// vim:syntax=lpc

//! This handler takes care of prefetching @[PSYC.Text.TextDB] entries,
//! so that @expr{sometextdb[mc]@} returns the template (if existing) once
//! the packet is approved for further processing.
//!
//! This handler will handle every method in stage prefilter.
//!
//! Requires no variables from storage whatsoever.
//!
//! Accesses: @expr{parent->attache->textdb@}.

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
