// vim:syntax=lpc
#include <debug.h>

inherit PSYC.Handler.Base;
array history;

constant _ = ([ 
    "casted" : ([
	"" : 0,
    ]),
    "postfilter" : ([
	
    ]),
]);

int casted(MMP.Packet p, mapping _v) {
    MMP.Packet entry = p->clone();
    entry->data = entry->data->clone(); // assume psyc packet...
    entry->data->vars->_time_place = time();
    history += ({ entry });

    return PSYC.Handler.GOON;
}

// need to check if source() is member, or something
// this needs some ueberarbeitung. there are plans for history/
// message retrieval somewhere and we should put them together.
// TODO
int postfilter_request_history() {
    foreach (parent->history;; MMP.Packet m) {
	if (has_prefix(m->data->mc,"_message")) {
	    MMP.Packet nm = m->clone();
	    nm->vars->_target = p->lsource();
	    nm->vars->_source_relay = m["_source"]||m["_source_relay"];
	    sendmmp(p->lsource(), nm);
	}
    }
    return PSYC.Handler.STOP;
}
