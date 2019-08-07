# -*- perl -*-

# Copyright (c) 2008 by Jeff Weisberg
# Author: Jeff Weisberg <jaw @ tcp4me.com>
# Created: 2008-Dec-16 11:56 (EST)
# Function: our on the wire protocol
#
# $Id$

package AC::Protocol;
use AC::DC::Protocol;
use AC::Misc;
use Time::HiRes 'alarm';
use Digest::SHA1;
use Socket;
use strict;

our @ISA = 'AC::DC::Protocol';


my $VERSION = 0x41433032;
my $BUFSIZ  = 65536;

my %MSGTYPE =
 (
  status		=> { num => 0, reqc => '', 			resc => 'ACPStdReply' },
  heartbeat		=> { num => 1, reqc => '', 			resc => '' },
  heartbeat_request	=> { num => 2, reqc => '', 			resc => 'ACPHeartBeat' },

  yenta_status		=> { num => 6, reqc => 'ACPYentaStatusRequest', resc => 'ACPYentaStatusReply' },
  yenta_get		=> { num => 7, reqc => 'ACPYentaGetSet',        resc => 'ACPYentaGetSet' },
  yenta_distrib		=> { num => 8, reqc => 'ACPYentaDistRequest',   resc => 'ACPYentaDistReply' },
  yenta_check		=> { num => 9, reqc => 'ACPYentaCheckRequest',  resc => 'ACPYentaCheckReply' },

  scribl_put		=> { num => 11, reqc => 'ACPScriblRequest',     resc => 'ACPScriblReply' },
  scribl_get		=> { num => 12, reqc => 'ACPScriblRequest',     resc => 'ACPScriblReply' },
  scribl_del		=> { num => 13, reqc => 'ACPScriblRequest',     resc => 'ACPScriblReply' },
  scribl_stat		=> { num => 14, reqc => 'ACPScriblRequest',     resc => 'ACPScriblReply' },

  mrmagoo_jobcreate	=> { num => 15, reqc => 'ACPMRMJobCreate',      resc => 'ACPStdReply' },
  mrmagoo_taskcreate	=> { num => 16, reqc => 'ACPMRMTaskCreate',     resc => 'ACPStdReply' },
  mrmagoo_jobabort	=> { num => 17, reqc => 'ACPMRMJobAbort',       resc => 'ACPStdReply' },
  mrmagoo_taskabort	=> { num => 18, reqc => 'ACPMRMTaskAbort',      resc => 'ACPStdReply' },
  mrmagoo_taskstatus	=> { num => 19, reqc => 'ACPMRMTaskStatus',     resc => 'ACPStdReply' },
  mrmagoo_filexfer	=> { num => 20, reqc => 'ACPMRMFileXfer',       resc => 'ACPStdReply' },
  mrmagoo_filedel	=> { num => 21, reqc => 'ACPMRMFileDel',        resc => 'ACPStdReply' },
  mrmagoo_diagmsg	=> { num => 22, reqc => 'ACPMRMDiagMsg',        resc => 'ACPStdReply' },
  mrmagoo_xferstatus	=> { num => 23, reqc => 'ACPMRMXferStatus',     resc => 'ACPStdReply' },
  mrmagoo_status	=> { num => 24, reqc => 'ACPMRMStatusRequest',  resc => 'ACPMRMStatusReply' },

 );


for my $name (keys %MSGTYPE){
    my $r = $MSGTYPE{$name};
    __PACKAGE__->add_msg( $name, $r->{num}, $r->{reqc}, $r->{resc});
}


1;
