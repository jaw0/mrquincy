/*
  Copyright (c) 2014
  Author: Jeff Weisberg <jaw @ solvemedia.com>
  Created: 2014-Mar-24 12:32 (EDT)
  Function: 

*/

#define CURRENT_SUBSYSTEM	'y'

#include "defs.h"
#include "diag.h"
#include "config.h"
#include "misc.h"
#include "hrtime.h"
#include "network.h"
#include "lock.h"

#include <sys/types.h>
#include <poll.h>
#include <sys/socket.h>
#include <signal.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/stat.h>
//#include <sys/loadavg.h>

extern int job_nrunning(void);

static Mutex lock;
static int seqno = 42;


struct Gunk {
    int t;
    int i;
    short p;
    short n;
};

void
unique(string *dst){
    char buf[32];
    struct Gunk g;

    g.t = lr_now();
    g.i = myipv4;
    g.p = getpid();

    lock.lock();
    g.n = seqno ++;
    lock.unlock();

    base64_encode((const char*)&g, sizeof(g), buf, sizeof(buf));

    // safe encode: / => _
    for(int i=0; i<sizeof(buf); i++){
        if( buf[i] == '/' ) buf[i] = '_';
    }

    dst->append(buf);

}

void
hexdump(const char *txt, const uchar *d, int l){

    if( txt ) fprintf(stderr, "%s:\n", txt);
    for(int i=0; i<l; i++){
        fprintf(stderr, " %02X", d[i]);
        if( (i%16)==15 && i!=l-1 ) fprintf(stderr, "\n");
    }
    fprintf(stderr, "\n\n");
}

int
current_load(void){
    double load[3];

    getloadavg( load, 3 );

    return (int)(load[1] * 1000) + job_nrunning() * 100;
}

int
mkdirp(const char *path, mode_t mode){
    char buf[PATH_MAX];
    int r;

    r = mkdir(path, mode);

    if( r == 0 ) return 0; 		// created. done.
    if( errno == EEXIST ) return 0; 	// already exists. done.

    const char *pe = path;
    while(1){
        const char *s = strchr(pe+1, '/');
        if( !s )    break; // no more slashes
        if( !s[1] ) break; // path ends with slash
        strncpy(buf, path, s - path);
        buf[s-path] = 0;
        pe = s;

        r = mkdir(buf, mode);
        if( r && (errno != EEXIST) ) return -1;
    }

    r = mkdir(path, mode);
    if( r && (errno != EEXIST) ) return -1;
    return 0;
}

