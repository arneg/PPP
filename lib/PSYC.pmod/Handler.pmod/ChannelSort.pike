// vim:syntax=lpc
#include <debug.h>

inherit PSYC.Handler.Base;

constant _ = ([ 
    "filter" : ([
	"_request_add_member" : ([ "async" : 1 ]),
	"_request_remove_member" : ([ "async" : 1 ]),
    ]),
    "postfilter" : ([
	"_request_add_member" : 0,
	"_request_remove_member" : 0,
    ]),
]);

constant export = ({ });

void filter_request_add_member(MMP.Packet p, mapping _v, mapping _m, function cb) {
    PSYC.Packet m = p->data;

    if (!MMP.is_uniform(m["_channel"]) || !m["channel"]->channel ||
	!MMP.is_uniform(m["_member"])) {
	sendmsg(p->reply(), p->data->reply("_error"+m->mc));

	MMP.Utils.invoke_later(cb, PSYC.Handler.STOP);
	return;		
    }

    void callback(int priv) {
	if (priv) {
	    MMP.Utils.invoke_later(cb, PSYC.Handler.GOON);
	} else {
	    sendmsg(p->reply(), p->data->reply("_failure_privileges_required"));
	    MMP.Utils.invoke_later(cb, PSYC.Handler.STOP);
	}
    };

    parent->is_admin(p->source(), callback);
}

int postfilter_request_add_member(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;
    MMP.Uniform member = m["_member"];
    MMP.Uniform channel = m["_channel"];
    
    parent->channel_add(channel, member);

    return PSYC.Handler.STOP;
}

function filter_request_remove_member = filter_request_add_member;

int postfilter_request_remove_member(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;
    MMP.Uniform member = m["_member"];
    MMP.Uniform channel = m["_channel"];

    parent->channel_remove(channel, member);

    return PSYC.Handler.STOP;
}
