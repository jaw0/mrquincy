# -*- perl -*-

# Copyright (c) 2014
# Author: Jeff Weisberg <jaw @ solvemedia.com>
# Created: 2014-Mar-31 22:53 (EDT)
# Function: compile job into ruby

package AC::MrQuincy::Submit::Compile::Ruby;
use AC::Import;
use AC::Dumper;
use IPC::Open3;
use JSON;
use strict;

our @EXPORT = 'compile_ruby';

# defaults, may be overridden in Compile->new
my $RUBYBIN	= '/usr/bin/ruby';
my $LIBDIR	= '/home/mrquincy/lib/ruby';

sub compile_ruby {
    my $comp  = shift;
    my $parse = shift;

    my $prog = $parse->{content};

    my @job;

    $comp->{confjs}   = encode_json( $comp->{config} );

    # compile + run init section
    # if( $comp->{runinit} && $prog->{init} ){
    #     my $init = compile_init( $comp, $prog );
    #     my $code = $init->{src};
    #     my $r = eval $code;
    #     die if $@;
    #     $comp->{initjs} = encode_json($r) if $r;
    # }

    $comp->{initjs} ||= encode_json({});

    push @job, compile_map( $comp, $prog );
    if( $prog->{reduce} ){
        for my $i (0 .. @{$prog->{reduce}}-1){
            push @job, compile_reduce( $comp, $prog, $i );
        }
    }
    if( $prog->{final} ){
        push @job, compile_final( $comp, $prog );
    }

    # print STDERR dumper(\@job); exit;
    for my $j (@job){
        syntax_check( $comp, $j->{phase}, $j->{src} );
    };

    return \@job;
}

sub boilerplate {
    my $comp = shift;
    my $prog = shift;

    my $ruby = $comp->{rubybin} || $RUBYBIN;
    my $libs = $comp->{libdir}  || $LIBDIR;
    $libs = [ $libs ] unless ref $libs;

    my $code = "#!$ruby\n";
    $code .= "\$LOAD_PATH.unshift '$_'\n" for @$libs;

    $code .= <<EOBP;
require 'AC/MrQuincy/runtime'
require 'json'

$prog->{common}

EOBP
    ;
    return $code;
}

sub compile_init {
    my $comp = shift;
    my $prog = shift;

    my $sec = $prog->{init};

    my $code = boilerplate($comp, $prog, $sec);
    my $uniq = "$$\_$^T\_" . int(rand(0xffff));

    $code .= <<EOCONF;
\$R = begin
  conf = JSON.parse(<<'__END_OF_CONFIG_$uniq\__', {symbolize_names: true})
$comp->{confjs}
__END_OF_CONFIG_$uniq\__
  MrQuincy::Runtime.new conf, nil
end

$sec->{code}

EOCONF
    ;

    return {
        phase	=> 'init',
        maxrun	=> $comp->config( 'maxrun',      $sec ),
        timeout => $comp->config( 'tasktimeout', $sec ),
        src	=> $code,
    };
}

sub compile_common {
    my $comp = shift;
    my $prog = shift;
    my $sec  = shift;
    my $name = shift;
    my $loop = shift;
    my $argl = shift;

    my $code = boilerplate($comp, $prog);
    my $uniq = "$$\_$^T\_" . int(rand(0xffff));

    $code .= <<EOCOMMON;
\$R = begin
  conf = JSON.parse(<<'__END_OF_CONFIG_$uniq\__', {symbolize_names: true})
$comp->{confjs}
__END_OF_CONFIG_$uniq\__
  init = JSON.parse(<<'__END_OF_INITRES_$uniq\__', {symbolize_names: true})
$comp->{initjs}
__END_OF_INITRES_$uniq\__

  MrQuincy::Runtime.new conf, init
end

EOCOMMON
    ;

    $code .= $sec->{init} if $sec->{init};
    $code .= "\ndef program $argl\n$sec->{code}\nreturn\nend\n";
    $code .= $loop;
    $code .= $sec->{cleanup} if $sec->{cleanup};

    return {
        phase	=> $name,
        maxrun	=> $comp->config( 'maxrun',      $sec ),
        timeout => $comp->config( 'tasktimeout', $sec ),
        width	=> $comp->config( 'taskwidth',   $sec ),
        src	=> $code,
    };
}

sub compile_map {
    my $comp = shift;
    my $prog = shift;

    my $sec = $prog->{map};

    my $loop = "\n";

    if( $prog->{filterinput} ){
        $loop .= "def filterinput (data)\n$prog->{filterinput}{code}\nend\n";
    }
    if( $prog->{readinput} ){
        $loop .= "def readinput (data)\n$prog->{readinput}{code}\nend\n";
    }

    $loop .= "  \$stdin.each { |data|\n";

    if( $comp->config('lineinput', $sec) ){
        # read text line by line
        # nop
    }elsif( $prog->{readinput} ){
        # use provided decoder
        $loop .= "    data = readinput data\n";
    }else{
        # json decode
        $loop .= "    data = JSON.parse data, {symbolize_names: true}\n";
    }

    if( $prog->{filterinput} ){
        $loop .= "    next unless filterinput data\n";
    }else{
        $loop .= "    next unless \$R.filter data\n";
    }

    $loop .= <<'EOW';
    key, data = program data
    $R.output key, data unless key.nil?
  }
EOW
    ;

    return compile_common($comp, $prog, $sec, 'map', $loop, '(data)');
}

sub compile_reduce {
    my $comp = shift;
    my $prog = shift;
    my $nred = shift;

    my $sec = $prog->{reduce}[$nred];
    my $loop = <<'EOW';

    begin
      iter = MrQuincy::Iter.new $stdin
      iter.each_key { |k|
        key, data = program k, iter
        $R.output key, data unless key.nil?
      }
    end
EOW
    ;

    return compile_common($comp, $prog, $sec, "reduce/$nred", $loop, '(key, iter)');
}


sub compile_final {
    my $comp = shift;
    my $prog = shift;

    my $sec = $prog->{final};

    my $loop = <<'EOW';

    $stdin.each { |line|
      d = JSON.parse( line, {symbolize_names: true} )
      o = program *d
      $R.output *o if o
    }
EOW
    ;

    return compile_common($comp, $prog, $sec, 'final', $loop, '(key, data)');
}

sub syntax_check {
    my $comp = shift;
    my $name = shift;
    my $code = shift;

    return if $comp->{no_syntax_check};
    my $file = "/tmp/mrjob.$$";

    open(my $tmp, '>', $file);
    print $tmp $code;
    close $tmp;

    my $ruby = $comp->{rubybin} || $RUBYBIN;

    my $pid = open3(undef, \*CHLD_OUT, undef,  $ruby, '-c', $file);

    my $out;
    while(<CHLD_OUT>){ $out .= $_ }
    waitpid( $pid, 0 );
    my $status = $?;
    unlink $tmp;

    if( $status ){
        print STDERR "syntax error checking section $name\n";
        print STDERR $out;
        exit -1;
    }

    return 1;

}


1;
