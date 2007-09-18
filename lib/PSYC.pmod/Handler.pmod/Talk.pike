// vim:syntax=lpc
#include <debug.h>

inherit PSYC.Handler.Base;


//! This Handler may be used for Channels only.

constant _ = ([ 
    "postfilter" : ([
	"_message_public" : 0,
    ]),
]);

constant export = ({ });

int postfilter_message_public(MMP.Packet p, mapping _v, mapping _m) {

    parent->castmsg(p->data);
    return PSYC.Handler.STOP;
}
