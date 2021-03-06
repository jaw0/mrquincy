/*
  Copyright (c) 2014
  Author: Jeff Weisberg <jaw @ solvemedia.com>
  Created: 2014-Mar-14 11:54 (EDT)
  Function: base64 encode

*/

// url + filename safe encoding
static const char charset[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";


void
base64_encode(const char *xsrc, int slen, char *dst, int dlen){
    const unsigned char *src = (const unsigned char*)xsrc;
    unsigned int l;

    // make sure dst is terminated on empty input
    if( dlen ) *dst = 0;

    while(slen){
        unsigned int e=0;
        int il=slen>3 ? 3 : slen;
        slen -= il;

        if( dlen < 5 ) return;

        switch(il){
        case 3:
            e |= (*src++) << 16;
            // fall thru
        case 2:
            e |= (*src++) << ((4 - il)<<3);
            // fall thru
        case 1:
            e |= (*src++) << ((3 - il)<<3);
            break;
        }

        // output chars
        *dst++ = charset[ (e>>18) & 0x3f ];
        *dst++ = charset[ (e>>12) & 0x3f ];

        if(il > 1 ){
            *dst++ = charset[ (e>> 6) & 0x3f ];
            if( il > 2 )
                *dst++ = charset[ (e    ) & 0x3f ];
        }

        // output padding
        switch(il){
        case 1:
            *dst++ = '=';
            // fall thru
        case 2:
            *dst++ = '=';
            break;
        }

        *dst = 0;
        dlen -= 4;
    }
}

