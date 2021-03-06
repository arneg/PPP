// vim:syntax=lpc
#include <new_assert.h>

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
#define ENTER		0
#define LEAVE		1
#define CAST		2

inherit PSYC.Handler.Base;

mapping callbacks = ([ ]);
mapping requests = ([ ]);

constant _ = ([
    "postfilter" : ([
	"_request_context_enter" : ([
	    "async" : 1,
	    "check" : "is_us",
	]),
	"_request_context_leave" : ([
	    "check" : "is_us",
	]),
    ]),
]);

constant export = ({
    "castmsg", "create_channel", "channel_remove", "channel_exists", "channel_add"
});

void init_handler() {
    register_incoming(([ "stage" : "postfilter", "method":Method("_request_context_enter"), "vars":Vars(([ "_group" : Uniform(), "_supplicant" : Uniform() ])), "async" : 1 ]));
    register_incoming(([ "stage" : "postfilter", "method":Method("_request_context_leave"), "vars":Vars(([ "_group" : Uniform(), "_supplicant" : Uniform() ])) ]));
}


int channel_exists(MMP.Uniform channel) {
    return has_index(callbacks, channel);
}

//! Creates a channel.
//! @param channel
//! 	The uniform of the channel to be created. Must be a channel of the 
//! 	entity's uniform (or the uniform itself to create the default channel).
//! @param enter
//! 	Is called whenever someone requested to enter a channel. Signature:
//! 	@expr{void enter(MMP.Uniform guy, function callback, mixed ... args);@}
//! 	
//! 	@expr{callback@} should then be called with an integer (@expr{1@} to 
//!	allow the enter, @expr{0@} to deny it) as the first argument followed 
//!	by expanded args.
//! @param leave
//! 	Callback to be called in case someone wants to leave the channel. There
//! 	is no way to keep someone from leaving, therefore the expected signature is:
//! 
//! 	@expr{void leave(MMP.Uniform guy);@}
//! @note
//! 	Both callbacks @expr{enter@} and @expr{leave@} are not called when @[channel_add()] or
//! 	@[channel_remove()] have been used. You are supposed to keep track of those changes 
//! 	on your own.
//! @throws
//! 	Throws a exception if the given @expr{channel@} does not fit the requirements. 
//! @fixme
//! 	not entirely sure about the above note. look at what Root replys with. on_castmsg 
//! 	feels like a hack..
void create_channel(MMP.Uniform channel, function|void enter, void|function leave, void|function on_castmsg) {

    if (channel->channel ? (channel->super != uni) : (channel != uni)) {
	do_throw("cannot create channel %O in %O because it doesnt belong there.\n", channel, uni);
    }
    callbacks[channel] = ({ enter, leave, on_castmsg });
}

int prefetch_postfilter_request_context_enter(MMP.Packet p, mapping misc) {
    mapping vars = p->data->vars;

    if (!has_index(p->vars, "_context")) {
	MMP.Uniform group = vars["_group"];
	if ((group->channel ? group->super : group) == uni) {
	    debug("multicast_routing", 2, "is_us check true for %O.\n", p);
	    return PSYC.Handler.GOON;
	}
    }
    
    debug("multicast_routing", 2, "is_us check is false for %O.\n", p);
    return PSYC.Handler.STOP;
}

void postfilter_request_context_enter(MMP.Packet p, mapping _v, mapping _m, function cb) {
    MMP.Uniform source = p->source();
    PSYC.Packet m = p->data;
    MMP.Uniform group = m["_group"];
    MMP.Uniform supplicant = m["_supplicant"];

    debug("multicast_routing", 2, "%O: request to enter %O from %O.\n", parent, group, source);

    if (!has_index(callbacks, group)) {
	// blub
	debug("multicast_routing", 0, "Channel does not exist.\n");
	sendmsg(p->source(), m->reply("_failure_context_enter"));
	call_out(cb, 0, PSYC.Handler.STOP);
	return;
    }

    void callback(int may, MMP.Packet p) {
	if (may) {
	    sendmsg(p->source(), m->reply("_notice_context_enter", ([ "_supplicant" : supplicant, "_group" : group ])));
	} else {
	    sendmsg(p->source(), m->reply("_notice_context_discord", ([ "_supplicant" : supplicant, "_group" : group ])));
	}
    };

    if (!callbacks[group][ENTER]) {
	sendmsg(p->source(), m->reply("_notice_context_enter", ([ "_supplicant" : supplicant, "_group" : group ])));
	sendmsg(p->source(), PSYC.Packet("_status_context_open", ([ "_group" : group ])));
	call_out(cb, 0, PSYC.Handler.STOP);
	return;
    }

    callbacks[group][ENTER](supplicant, callback, p);

    call_out(cb, 0, PSYC.Handler.STOP);
}

int prefetch_postfilter_request_context_leave(MMP.Packet p, mapping misc) {
    return prefetch_postfilter_request_context_enter(p, misc);
}

int postfilter_request_context_leave(MMP.Packet p, mapping _v, mapping _m) {
    MMP.Uniform source = p->source();
    PSYC.Packet m = p->data;
    MMP.Uniform group = m["_group"];
    
    if (callbacks[group][LEAVE]) {
	callbacks[group][LEAVE](m["_supplicant"]);
    }

    return PSYC.Handler.STOP;
}

//! Remove someone from the multicast channel. Does not and cannot check
//! if @expr{entity@} is subscribes to @expr{channel@}. That information
//! is kept only on routing level. However, if @expr{entity@} happens to
//! be on the list of subscribers, it will be removed.
//! 
//! @note
//! 	You should keep track of membership yourself. That can be done
//! 	by using the callbacks to @[create_channel()].
void channel_remove(MMP.Uniform channel, MMP.Uniform entity) {
    enforcer(has_index(callbacks, channel), 
	     "Trying to remove someone from nonexisting channel.\n");

    sendmsg(channel->root, PSYC.Packet("_notice_context_leave", 
				       ([ "_group" : channel,
				          "_supplicant" : entity ])));
}

//! Add an entity to a channel. @expr{entity@} must already be subscribed
//! to the default channel, otherwise this will not work.
//! @throws
//! 	This method will throw if @expr{channel@} is the default channel
//! 	as entities cannot be forced into it.
void channel_add(MMP.Uniform channel, MMP.Uniform entity) {
    debug("multicast_routing", 2, "%O->channel_add(%O)\n", channel, entity);

    enforcer(has_index(callbacks, channel), 
	     "Trying to add someone to nonexisting channel.\n");

    enforcer(channel->channel, 
	     "Trying to add someone to the default channel.\n");

    sendmsg(channel->root, PSYC.Packet("_notice_context_enter_channel",
				       ([ "_group" : channel,
				          "_supplicant" : entity ])));
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
    debug("multicast_routing", 2, "%O->castmsg(%O, %O)\n", channel, m, source_relay);

    if (!has_index(callbacks, channel)) {
	do_throw("castmsg in non-existing channel.\n", channel);
    }


    MMP.Packet p = MMP.Packet(m, ([ "_context" : channel, 
				    "_source_relay" : source_relay,
				    ]));

    parent->handle("notify", "castmsg", p, channel);
    parent->server->get_context(channel)->msg(p); 
}
