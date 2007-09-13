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
int postfilter_request_history() {
    //
    //
    return PSYC.Handler.STOP;
}
