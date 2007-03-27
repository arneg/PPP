#include <debug.h>
inherit PSYC.Handler.Base;

//! This handler calls @expr{parent->distribute(mmppacket);@} for every
//! message received.
//!
//! Requires no variables from storage whatsoever.

constant _ = ([
    "display" : ([
	"" : 0
    ])
]);

int display(MMP.Packet p, mapping _v, mapping _m) {
    PT(("Handler.Forward", "postfilter(%O)\n", p))

    call_out(parent->distribute, 0 ,p);
    return PSYC.Handler.GOON;
}
