// vim:syntax=lpc
#include <debug.h>

inherit PSYC.Handler.Base;

constant _ = ([
    "prefilter" : ([
	"" : ([ "async" : 1 ]),
    ]),
]);

void verycomplexcallback(int s, function cb) {
    call_out(cb, 0, PSYC.Handler.GOON);
}

void prefilter(MMP.Packet p, mapping _v, mapping _m, function cb) {
    PSYC.Packet m = p->data;

    parent->attachee->textdb->fetch(m->mc, verycomplexcallback, cb);
    //uni->attachee->textdb->fetch(m->mc, call_out, cb, 0, PSYC.Handler.GOON);
}
