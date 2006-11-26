// vim:syntax=lpc
#include <debug.h>

inherit PSYC.Handler.Base;

constant _ = ([
    "filter" : ([
	"" : ([ "async" : 1 ]),
    ]),
]);

#if 0
void verycomplexcallback(int s, function cb) {
    call_out(cb, 0, PSYC.Handler.GOON);
}
#endif

void filter(MMP.Packet p, mapping _v, mapping _m, function cb) {
    PSYC.Packet m = p->data;

    // uni->attachee->textdb->fetch(m->mc, verycomplexcallback, cb);
    uni->attachee->textdb->fetch(m->mc, call_out, cb, 0, PSYC.Handler.GOON);
}
