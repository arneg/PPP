// vim:syntax=lpc
#include <debug.h>


// generic channel/subscription implementation. should be working ok for:
// * places with different channels
// * presence subscription (also having several channels as different groups in the buddylist)
// * sync notifications for storage.
//
// requirements to channels:
// * subscription by the user
#define SUBSCRIBE 	0
#define ENTER		1
#define LEAVE		2

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
	"_request_context_leave" : 0,
    ]),
]);

constant export = ({
    "castmsg", "create_channel"
});

void create_channel(MMP.Uniform channel, function|void subscribe, function|void enter, void|function leave) {

    if (channel->root != uni) {
	THROW(sprintf("cannot create channel %O in %O because it doesnt belong there.\n", channel, uni));
    }
    callbacks[channel] = ({ subscribe, enter, leave });
}

void postfilter_request_context_enter(MMP.Packet p, mapping _v, mapping _m, function cb) {
    MMP.Uniform source = p->source();
    PSYC.Packet m = p->data;
    MMP.Uniform group = m["_group"];

    if (!has_index(callbacks, group)) {
	// blub
	P0(("PSYC.Handler.Channel", "Channel does not exist.\n"))
	sendmsg(p->source(), m->reply("_failure_context_enter"));
	call_out(cb, 0, PSYC.Handler.STOP);
	return;
    }

    void callback(int may, MMP.Packet p) {
	if (may) {
	    sendmsg(p->source(), m->reply("_notice_context_enter", ([ "_supplicant" : m["_supplicant"], "_group" : group ])));
	} else {
	    sendmsg(p->source(), m->reply("_notice_context_discord", ([ "_supplicant" : m["_supplicant"], "_group" : group ])));
	}
    };

    if (!callbacks[group][1]) {
	sendmsg(p->source(), m->reply("_notice_context_enter", ([ "_supplicant" : m["_supplicant"], "_group" : group ])));
	sendmsg(p->source(), PSYC.Packet("_status_context_open", ([ "_group" : group ])));
	call_out(cb, 0, PSYC.Handler.STOP);
	return;
    }

    // maybe wrong!! should be supplicant not _source_relay.
    callbacks[group][1](p->lsource(), callback, p);

    call_out(cb, 0, PSYC.Handler.STOP);
}

int postfilter_request_context_leave(MMP.Packet p, mapping _v, mapping _m) {
    MMP.Uniform source = p->source();
    PSYC.Packet m = p->data;
    MMP.Uniform group = m["_group"];
    
    sendmsg(p->source(), m->reply("_notice_context_leave", ([ "_supplicant" : m["_supplicant"], "_group" : group ])));

    if (callbacks[group][LEAVE]) {
	callbacks[group][LEAVE](m["_supplicant"]);
    }

    return PSYC.Handler.STOP;
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
    parent->server->get_context(channel)->msg(p); 
}
