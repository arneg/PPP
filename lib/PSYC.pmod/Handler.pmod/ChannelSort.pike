
// vim:syntax=lpc
#include <debug.h>

inherit PSYC.Handler.Base;

constant _ = ([ 
    "filter" : ([
	"_request_add_member" : ({ "members", "admins" }),
	"_request_remove_member" : ({ "members", "admins" }),
    ]),
    "postfilter" : ([
	"_request_add_member" : ({ "members", "admins" }),
	"_request_remove_member" : ({ "members", "admins" }),
    ]),
]);

constant export = ({ });

int filter_request_add_member(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;

    if (!mappingp(_v["admins"])) {
	P0(("Handler.ChannelSort", "%O: no proper admins available in storage. Cannot authorize.\n", parent))
	sendmsg(p->reply(), p->data->reply("_error"+m->mc));

	return PSYC.Handler.STOP;		
    }

    if (!_v["admins"][p->source()]) {
	sendmsg(p->reply(), p->data->reply("_failure_privileges_required"));

	return PSYC.Handler.STOP;		
    }

    if (!MMP.is_uniform(m["_channel"]) || !m["channel"]->channel ||
	!MMP.is_uniform(m["_member"])) {
	sendmsg(p->reply(), p->data->reply("_error"+m->mc));

	return PSYC.Handler.STOP;		
    }
    
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
