// vim:syntax=lpc
#include <debug.h>

inherit PSYC.Handler.Base;

constant _ = ([
    "filter" : ([
	"" : ([ "async" : 1 ]),
    ]),
]);

void verycomplexcallback(int s, function cb) {
    call_out(cb, 0, PSYC.Handler.GOON);
}

void filter(MMP.Packet p, mapping _v, function cb) {
    PSYC.Packet m = p->data;

    uni->attachee->textdb->fetch(m->mc, verycomplexcallback, cb);
}
