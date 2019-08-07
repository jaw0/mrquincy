# -*- perl -*-

# Copyright (c) 2019
# Author: Jeff Weisberg <jaw @ tcp4me.com>
# Created: 2019-Aug-07 12:20 (EDT)
# Function: 

package AC::MrQuincy::ServerFile;
use AC::Import;
use JSON;
use strict;

our @EXPORT = 'get_ac_servers';

sub get_ac_servers {
    my $file = shift;
    my $env  = shift;
    my $sys  = shift;

    my $all = read_server_file($file);

    # filter
    my @res;

    for my $r (@$all){
        next unless $r->{Subsystem} eq $sys;
        next unless $r->{Environment} eq $env;
        next unless $r->{IsUp};

        for my $a (@{$r->{NetInfo}}){
            push @res, { Id => $r->{Id}, Addr => $a->{Addr} };
        }
    }

    @res;
}

sub read_server_file {
    my $file = shift;

    open(F, '<', $file) || die "cannot open '$file': $!\n";
    local $/ = undef;
    my $content = <F>;

    return decode_json($content);
}
