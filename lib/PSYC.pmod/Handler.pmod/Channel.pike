// vim:syntax=lpc
#include <debug.h>


// generic channel/subscription implementation. should be working ok for:
// * places with different channels
// * presence subscription (also having several channels as different groups in the buddylist)
// * sync notifications for storage.
//
// requirements to channels:
// * subscription by the user

inherit PSYC.Handler.Base;

mapping callbacks = ([ ]);

constant _ = ([
    "postfilter" : ([
	"_request_context_enter" : ([
	    "async" : 1,
	]),
	"_request_context_enter_subscribe" : ([
	    "async" : 1,
	]),
    ]),
]);

constant export = ({
    "castmsg", "create_channel"
});

void create_channel(MMP.Uniform channel, function|void subscribe, function|void enter) {
    callbacks[channel] = ({ subscribe, enter });
}

void postfilter_request_context_enter(MMP.Packet p, mapping _v, mapping _m, function cb) {
    MMP.Uniform target = p["_target"];
    MMP.Uniform source = p->source();
    PSYC.Packet m = p->data;

    if (!has_index(callbacks, target)) {
	// blub
	P0(("PSYC.Handler.Channel", "Channel does not exist.\n"))
	sendmsg(p->source(), m->reply("_failure_context_enter"));
	call_out(cb, 0, PSYC.Handler.STOP);
	return;
    }

    void callback(int may, MMP.Packet p) {
	if (may) {
	    sendmsg(p->source(), m->reply("_notice_context_enter", ([ "_supplicant" : m["_supplicant"] ])));
	} else {
	    sendmsg(p->source(), m->reply("_notice_context_discord", ([ "_supplicant" : m["_supplicant"] ])));
	}
    };

    if (!callbacks[target][1]) {
	sendmsg(p->source(), m->reply("_notice_context_enter", ([ "_supplicant" : m["_supplicant"] ])));
	sendmsg(p->source(), m->reply("_status_context_open"));
	call_out(cb, 0, PSYC.Handler.STOP);
	return;
    }

    callbacks[target][1](p->lsource(), callback, p);

    call_out(cb, 0, PSYC.Handler.STOP);
}

void postfilter_request_context_enter_subscribe(MMP.Packet p, mapping _v, mapping _m, function cb) {
    return PSYC.Handler.STOP;
}


void castmsg(MMP.Uniform channel, PSYC.Packet m, MMP.Uniform source_relay) {

    if (!has_index(callbacks, channel)) {
	THROW(("Handlers.Channel", "%O is very unlikely to contain anyone as you never created them.\n", channel));
    }

    MMP.Packet p = MMP.Packet(m, ([ "_context" : channel, 
				    "_source_relay" : source_relay,
				    ]));
    uni->server->get_context(channel)->msg(p); 
}
