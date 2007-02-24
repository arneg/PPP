// vim:syntax=lpc
#include <debug.h>

//! Implementation of PSYC channels, e.g. multicast groups. Does not keep 
//! track of its members on its own. That should be done persistently by
//! all routers engaged in the distribution of messages in a particular
//! channel. Offers a callback interface to implement more complex channel
//! structures on top.
//! 
//! Requires no variables from storage whatsoever.
//! 
//! PSYC Packets to be processed are those of type:
//! @pre{ 
//! _request_context_enter
//! _request_context_enter_subscribe
//! _request_context_leave
//! @}
//! 
//! Exports: @[create_channel()], @[castmsg()]
//! 
//! @note
//! 	This is not a handler you only need for channels, this rather is a
//! 	handler for groups in general, which has support for channels, too.
//! @seealso
//! 	@[PSYC.Root] for an implementation of PSYC multicast signaling, e.g.
//! 	the management of multicast groups on MMP routing level.


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

//! Creates a channel.
//! @param channel
//! 	The uniform of the channel to be created. Must be a channel of the 
//! 	entity's uniform (or the uniform itself to create the default channel).
//! @param subscribe
//! 	Is called whenever someone requested to enter a channel. Signature:
//! 	@expr{void subscribe(MMP.Uniform guy, function callback, mixed ... args);@}
//! 	
//! 	@expr{callback@} should then be called with an integer (@expr{1@} to 
//!	allow the subscribe, @expr{0@} to deny it) as the first argument followed 
//!	by expanded args.
//! @param enter
//! 	Same as @expr{subscribe@} but for requests to enter the channel.
//! @param leave
//! 	Callback to be called in case someone wants to leave the channel. There
//! 	is no way to keep someone from leaving, therefore the expected signature is:
//! 
//! 	@expr{void leave(MMP.Uniform guy);@}
//! @throws
//! 	Throws a exception if the given @expr{channel@} does not fit the requirements. 
void create_channel(MMP.Uniform channel, function|void subscribe, function|void enter, void|function leave) {

    if (channel->channel ? (channel->super != uni) : (channel != uni)) {
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


//! Casts a message to a channel (or the group).
//! @param channel
//! 	Channel to cast the message to, use the uniform of the entity for
//! 	the group ("default channel").
//! @param m
//! 	Packet to cast.
//! @param source_relay
//! 	Value to set @expr{_source_relay@} to in the sended MMP packets.
//! 	In a public room, this would the author of the @expr{_message_public@},
//! 	but may be every valid uniform and even 'faked'.
//! @throws
//! 	If the @expr{channel@} has never been created.
void castmsg(MMP.Uniform channel, PSYC.Packet m, MMP.Uniform source_relay) {

    if (!has_index(callbacks, channel)) {
	THROW(("Handlers.Channel", "%O is very unlikely to contain anyone as you never created them.\n", channel));
    }

    MMP.Packet p = MMP.Packet(m, ([ "_context" : channel, 
				    "_source_relay" : source_relay,
				    ]));
    parent->server->get_context(channel)->msg(p); 
}
