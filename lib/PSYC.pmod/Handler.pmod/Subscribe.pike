// vim:syntax=lpc
#include <debug.h>

inherit PSYC.Handler.Base;

//! Client side (in respect to member<->channel) implementation of channel
//! communications.
//!
//! Handles the following Message Classes:
//! @ul
//! 	@item
//! 		_notice_context_enter_channel
//! 	@item
//! 		_notice_context_leave
//! @endul
//! Additionally filters out all messages from a group we are not in.
//!
//! Open-heartedly uses the "places" storage variable.
//!
//! Exports:
//! @ul
//! 	@item
//! 		@expr{enter()@}
//! 	@item
//! 		@expr{leave()@}
//! @endul

#define REQUESTED(x)	(x&1)
#define SUBSCRIBED(x)	(x&2)

/* How it works:
 *
 * request membership in a context
 * get a _notice_enter for the context and/or any of his channels
 *
 */

constant _ = ([
    "_" : ({ "places" }),
    "filter" : ([ 
	"" : ([ 
	    "lock" : ({ "places" }),
	    "check" : "has_context",
	]),
    ]),
    "postfilter" : ([
#if 0
	"_notice_context_leave_subscribe" : ([
	    "lock" : ({ "places" }),
	    "async" : 1,
	]),
#endif
	"_notice_context_enter_channel" : ([
	    "lock" : ({ "places" }),
	    "async" : 1,
       ]),
	"_notice_context_leave" : ([
	    "lock" : ({ "places" }),
	    "async" : 1,
	]),
    ]),
]);

constant export = ({
    "enter", "leave", "really_unsubscribe"
});

void init(mapping vars) {
    if (!mappingp(vars["places"])) {
	parent->storage->set("places", ([]));
	set_inited(1);
    }
}

int has_context(MMP.Packet p, mapping _m) {
    return has_index(p->vars, "_context");
}

void postfilter_notice_context_leave(MMP.Packet p, mapping _v, mapping _m, function cb) {
    PSYC.Packet m = p->data;
    MMP.Uniform source = p->source();
    mapping sub = _v["places"];

    void callback(int error) {
	if (error) {
	    P0(("PSYC.Handler.Subscribe", "set_unlock failed for places. retry... \n."))

	    // in most cases this will be a loop.. most certainly.
	    //  we should do something else here..
	    parent->storage->set_unlock("places", sub, callback);
	    return;
	}

	call_out(cb, 0, PSYC.Handler.DISPLAY);
    };
    
    if (has_index(sub, source)) {
	m_delete(sub, source);

	parent->storage->set_unlock("places", sub, callback);
    }
}

int filter(MMP.Packet p, mapping _v, mapping _m) {
    MMP.Uniform channel = p["_context"];

    // we have a check for that, messages without context never get here
    // if (!channel) return PSYC.Handler.GOON;

    mapping sub = _v["places"];
    // we could aswell save the object of that channel into the uniform.. 
    // they are some somewhat related (instead of cutting the string everytime)
    if (channel->channel) {
	MMP.Uniform context = channel->super;

	if (!has_index(sub, channel)) {
	    if (has_index(sub, context)) {
		P0(("Handler.Subscribe", "%O: %O forgot to join us into %O.\n", parent, context, channel))
	    } else {
		P0(("Handler.Subscribe", "%O: we never joined %O but are getting messages from %O.\n", parent, context, channel))
	    }

	    sendmsg(channel, PSYC.Packet("_notice_context_leave_channel"));
	    return PSYC.Handler.STOP;
	}
    } else if (!has_index(sub, channel)) {
	P0(("Handler.Subscribe", "%O: we never joined %O but are getting messages.\n", parent, channel))
	sendmsg(channel, PSYC.Packet("_notice_context_leave"));

	return PSYC.Handler.STOP;
    }

    return PSYC.Handler.GOON;
}

void postfilter_notice_context_enter_channel(MMP.Packet p, mapping _v, mapping _m, function cb) {
    PSYC.Packet m = p->data;
    MMP.Uniform member = m["_supplicant"];
    MMP.Uniform channel = m["_group"];

    mapping sub = _v["places"];

    if (!channel->super) {
	// dum dump
	P1(("Handler.Subscribe", "%O: got channel join without channel from dump dump %O.\n", uni, p->source()))
	call_out(cb, 0, PSYC.Handler.STOP);
	return;
    }

    if (!has_index(sub, channel->super)) {
	P1(("Handler.Subscribe", "%O: illegal channel join to %O from %O.\n", uni, channel, p->source()))
	call_out(cb, 0, PSYC.Handler.STOP);
	return;
    }

    if (has_index(sub, channel)) {
	parent->storage->unlock("places");
    } else {
	sub[channel] = 1;
	parent->storage->set_unlock("places", sub);
    }

    call_out(cb, 0, PSYC.Handler.DISPLAY);
    return;
}

// ==================================

//! Enters a channel.
//! @param channel
//! 	The channel to enter.
//! @param error_cb
//! 	Callback to be called when the place can not be entered. Signature:
//! 	@expr{void error_cb(mixed ... args);@}.
//! 	Retring may work here.
//! @param args
//! 	Arguments to be passed on to the @expr{error_cb@}.
void enter(MMP.Uniform channel, function|void error_cb, mixed ... args) {

    // TODO: check if we subscribed to the corresponding context

    void callback(MMP.Packet p, mapping _v, function cb) {
	PSYC.Packet m = p->data;
	MMP.Uniform source = p->source();

	MMP.Uniform group;
	if (!has_index(m->vars, "_group") || !objectp(group = m["_group"])) {
	    group = channel; 
	}

	mapping sub = _v["places"];

	if (PSYC.abbrev(m->mc, "_notice_context_enter")) {
	    if (has_index(sub, group)) {
		P3(("Handler.Subscribe", "%O: Double joined %O.\n", parent, group))
		if (error_cb)
		    parent->storage->unlock("places", error_cb, @args);
		else 
		    parent->storage->unlock("places");
	    } else {
		sub[group] = 1;
		if (error_cb)
		    parent->storage->set_unlock("places", sub, error_cb, @args);
		else 
		    parent->storage->set_unlock("places", sub);
	    }
	} else if (PSYC.abbrev(m->mc, "_notice_context_discord")) {
	    if (error_cb)
		parent->storage->unlock("places", error_cb, @args);
	    else 
		parent->storage->unlock("places");
	}

	call_out(cb, 0, PSYC.Handler.DISPLAY);
    };

    send_tagged_v(uni->root, PSYC.Packet("_request_context_enter", 
						   ([ "_group" : channel, "_supplicant" : uni ])), 
		       ([ "lock" : (< "places" >), "async" : 1 ]), callback);
}

//! Leaves a channel.
//! @param channel
//! 	The channel to leave.
//! @param error_cb
//! 	Callback to be called when the place can not be left. 
//!	If this is not a local storage error, messages from the @expr{channel@} 
//! 	will be blocked henceforward.
//!	Signature:
//! 	@expr{void error_cb(mixed ... args);@}.
//! 	Retring may work here.
//! @param args
//! 	Arguments to be passed on to the @expr{error_cb@}.
//! @fixme
//! 	Make an error output for local storage errors.
void leave(MMP.Uniform channel, function|void error_cb, mixed ... args) {

    void callback(MMP.Packet p, mapping _v, function cb) {
	PSYC.Packet m = p->data;
	MMP.Uniform source = p->source();
	mapping sub = _v["places"];
	
	MMP.Uniform group;
	if (!has_index(m->vars, "_group") || !objectp(group = m["_group"])) {
	    group = channel; 
	}
	    
	void fun(int s, string key, function error_cb, array(mixed) args) {
	    error_cb(@args);
	};
	if (PSYC.abbrev(m->mc, "_notice_context_leave")) {
	    // TODO think about really_leave
#if 0
	    if (source != channel) {
		really_unsubscribe(channel);
		return;
	    }
#endif
	    if (has_index(sub, channel)) {
		m_delete(sub, channel);
		parent->storage->set_unlock("places", sub, fun, args);
	    } else {
		parent->storage->unlock("places", fun, args);
	    }
	} else if (has_index(sub, channel)) {
	    m_delete(sub, channel);
	    parent->storage->set_unlock("places", sub, fun, args);
	}

	call_out(cb, 0, PSYC.Handler.DISPLAY);
    };

    send_tagged_v(uni->root, PSYC.Packet("_request_context_leave", ([ "_group" : channel, "_supplicant" : uni ])), 
		       ([ "lock" : (< "places" >), "async" : 1 ]), callback);
}

void really_unsubscribe(MMP.Uniform channel) {
    string mc = "_notice_context_leave" + (channel->channel) ? "_channel" : "" + "_subscribe"; 

    void callback(string key, mapping sub) {
	if (!sub) {
	    // errrr...or
	    call_out(really_unsubscribe, 2, channel);
	    return;
	}

	if (has_index(sub, channel)) {
	    m_delete(sub, channel);
	    parent->storage->set_unlock("places", sub);
	} else {
	    parent->storage->unlock("places");
	}
    };

    parent->storage->get_lock("places", callback);
    sendmsg(channel, PSYC.Packet(mc));
}

