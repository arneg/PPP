// vim:syntax=lpc
#include <debug.h>

inherit PSYC.Handler.Base;
MMP.Uniform primitive; 

constant _ = ([
    "prefilter" : ([
	"" : 0,
    ]),
]);

void create(object o, function fun, MMP.Uniform uni, MMP.Uniform client_uni) {
    primitive = client_uni;
    ::create(o, fun, uni);
}

int prefilter(MMP.Packet p, mapping _v, mapping _m) {
    
    if (parent->link_to == p->source() && p->lsource() == primitive) {
	_m["itsme"] = 1;
    } else {
	_m["itsme"] = 0;
    }

    return PSYC.Handler.GOON;
}
