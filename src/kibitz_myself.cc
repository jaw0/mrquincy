/*
  Copyright (c) 2014
  Author: Jeff Weisberg <jaw @ solvemedia.com>
  Created: 2014-Mar-14 15:57 (EDT)
  Function: 

*/

#define CURRENT_SUBSYSTEM	'k'

#include "defs.h"
#include "diag.h"
#include "config.h"
#include "misc.h"
#include "runmode.h"
#include "network.h"
#include "hrtime.h"

#include <netdb.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <sys/resource.h>
#include <sys/statvfs.h>

#include "std_ipport.pb.h"
#include "mrmagoo.pb.h"

#include <strings.h>

#define BOOTTIME	60


static hrtime_t starttime = 0;
static char pinhost[256];
static uint32_t pinip4 = 0;


bool
NetAddr::is_self(void){

    if( ipv4 == pinip4 ) return 1;
    if( ipv4 == myipv4 ) return 1;

    return 0;
}

void
myself_init(void){
    struct hostent *he;

    starttime = lr_now();

    // find private internal network info
    // we name the private internal address "pin-$hostname"
    // you may need to adjust this for your network

    snprintf(pinhost, sizeof(pinhost), "pin-%s", myhostname);
    he = gethostbyname( pinhost );
    if( he && he->h_length ){
        pinip4 = ((struct in_addr *)*he->h_addr_list)->s_addr;
    }else{
        VERBOSE("no private network found: %s", pinhost);
    }
}

void
about_myself(ACPMRMStatus *g){
    hrtime_t now = lr_now();
    ACPIPPort *ip;
    struct statvfs vfs;

    g->set_hostname( myhostname );
    g->set_server_id( myserver_id.c_str() );
    g->set_datacenter( mydatacenter.c_str() );
    g->set_environment( config->environment.c_str() );
    g->set_subsystem( MYNAME );
    g->set_via( myserver_id.c_str() );
    g->set_path( "." );
    if( config->available && (runmode.mode() == RUN_MODE_RUN) ){
        g->set_status( (now > starttime + BOOTTIME) ? 200 : 102 );
    }else{
        g->set_status( 102 );
    }
    g->set_timestamp( now );
    g->set_lastup( now );
    g->set_boottime( starttime );

    g->set_sort_metric( current_load() );
    g->set_cpu_metric( config->hw_cpus );

    // determine disk space
    if( ! statvfs( config->basedir.c_str(), &vfs ) ){
        g->set_capacity_metric( vfs.f_bavail / 2048 );	// MB avail
    }

    // ip info
    ip = g->add_ip();
    ip->set_ipv4( ntohl(myipv4) );
    ip->set_port( myport );

    if( pinip4 ){
        ip = g->add_ip();
        ip->set_ipv4( ntohl(pinip4) );
        ip->set_port( myport );
        ip->set_natdom( mydatacenter.c_str() );
    }
}

