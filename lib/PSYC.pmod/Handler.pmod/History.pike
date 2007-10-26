// vim:syntax=lpc
#include <debug.h>

inherit PSYC.Handler.Base;
array history = ({});

constant _ = ([ 
    "casted" : ([
	"_message" : 0,
    ]),
    "postfilter" : ([
	"_request_history" : 0,
    ]),
]);

int casted_message(MMP.Packet p, mapping _v) {
    debug("Handler.History", 2, "storing: %O.\n", p->data);
    MMP.Packet entry = p->clone();
    entry->data = entry->data->clone(); // assume psyc packet...
    entry->data->vars->_time_place = time();
    history += ({ entry });
    debug("Handler.History", 5, "stored: %d\n", sizeof(history));

    return PSYC.Handler.GOON;
}

// need to check if source() is member, or something
// this needs some reworking. there are plans for history/
// message retrieval somewhere and we should put them together.
// TODO
int postfilter_request_history(MMP.Packet p, mapping _v, mapping _m) {
    debug("Handler.History", 5, "postfilter_request_history(%O): %O.\n", p, history);
    foreach (history;; MMP.Packet m) {
	MMP.Packet nm = m->clone();
	nm->vars->_target = p->lsource();
	nm->vars->_source_relay = m["_source"]||m["_source_relay"];
	sendmmp(p->lsource(), nm);
    }
    return PSYC.Handler.STOP;
}
