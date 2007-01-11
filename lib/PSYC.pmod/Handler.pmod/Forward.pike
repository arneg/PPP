#include <debug.h>
inherit PSYC.Handler.Base;

constant _ = ([
    "postfilter" : ([
	"" : 0
    ])
]);

int postfilter(MMP.Packet p, mapping _v, mapping _m) {
    PT(("Handler.Forward", "postfilter(%O)\n", p))

    call_out(parent->distribute, 0 ,p);
    return PSYC.Handler.GOON;
}
