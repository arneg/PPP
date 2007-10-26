// vim:syntax=lpc

inherit PSYC.Handler.Base;

constant _ = ([ 
    "filter" : ([
	"_request_member_add" : ([ "async" : 1 ]),
	"_request_member_remove" : ([ "async" : 1 ]),
    ]),
    "postfilter" : ([
	"_request_member_add" : 0,
	"_request_member_remove" : 0,
    ]),
]);

constant export = ({ });

void filter_request_member_add(MMP.Packet p, mapping _v, mapping _m, function cb) {
    PSYC.Packet m = p->data;

    if (!MMP.is_uniform(m["_channel"]) || !m["_channel"]->channel ||
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

int postfilter_request_member_add(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;
    MMP.Uniform member = m["_member"];
    MMP.Uniform channel = m["_channel"];
    
    parent->channel_add(channel, member);

    return PSYC.Handler.STOP;
}

function filter_request_member_remove = filter_request_member_add;

int postfilter_request_member_remove(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;
    MMP.Uniform member = m["_member"];
    MMP.Uniform channel = m["_channel"];

    parent->channel_remove(channel, member);

    return PSYC.Handler.STOP;
}
