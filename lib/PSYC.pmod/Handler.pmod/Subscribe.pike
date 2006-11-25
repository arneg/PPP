// vim:syntax=lpc
#include <debug.h>

inherit PSYC.Handler.Base;

#define REQUESTED(x)	(x&1)
#define SUBSCRIBED(x)	(x&2)

/* How it works:
 *
 * request membership in a context
 * get a _notice_enter for the context and/or any of his channels
 *
 */

constant _ = ([
    "filter" : ([ 
	"" : ([ 
	    "lock" : ({ "_subscriptions" }),
	    "check" : "has_context",
	]),
    ]),
    "postfilter" : ([
	"_notice_context_enter_channel" : ([
	    "lock" : ({ "_subscriptions" }),
	]),
	"_notice_context_enter" : ([
	    "lock" : ({ "_subscriptions" }),
	]),
    ]),
]);

int has_context(MMP.Packet p, mapping _m) {
    return has_index(p->vars, "_context");
}

int postfilter_notice_context_enter_channel_subscribe(MMP.Packet p, mapping _v, mapping _m) {
    MMP.Uniform channel = p["_source"];

    if (!channel->channel) {
	P0(("Handler.Subscribe", "%O: got _notice_context_enter_channel from non-channel (%O).\n", uni, channel))
	sendmsg(channel, PSYC.Packet("_notice_context_leave"));
	return PSYC.Handler.STOP;
    }

    mapping sub = string2uniform(_v["_subscriptions"], 1);

    MMP.Uniform context = uni->server->get_uniform(channel->super);

    if (has_index(sub, context) && REQUESTED(sub[context])) {

	if (!SUBSCRIBED(sub[context])) {
	    sub[context] = SUBSCRIBED(255);
	    sub[channel] = SUBSCRIBED(255);
	    uni->storage->set_unlock("_subscriptions", sub);
	} else if (!SUBSCRIBED(sub[channel])) {
	    sub[channel] = SUBSCRIBED(255);
	    uni->storage->set_unlock("_subscriptions", sub);
	} else {
	    uni->storage->unlock("_subscriptions");
	}

    } else {
	P1(("Handler.Subscribe", "%O: someone (%O) tried to forcefully join us into his channel (%O).\n", uni, context, channel))
	sendmsg(channel, PSYC.Packet("_notice_context_leave_channel"));
    }

    return PSYC.Handler.STOP;
}

int postfilter_notice_context_enter_subscribe(MMP.Packet p, mapping _v, mapping _m) {
    MMP.Uniform context = p["_source"];

    if (context->channel) {
	P0(("Handler.Subscribe", "%O: _notice_context_enter from a channel (%O)!!!\n", context))	
	return PSYC.Handler.STOP;
    }

    mapping sub = string2uniform(_v["_subscriptions"], 1);

    if (has_index(sub, context) && REQUESTED(sub[context])) {
	P3(("Handler.Subscribe", "%O: joined a context (%O).\n", uni, context))
	if (!SUBSCRIBED(sub[context])) {
	    sub[context] = SUBSCRIBED(255);
	    uni->storage->set_unlock("_subscriptions", sub);
	} else {
	    uni->storage->unlock("_subscriptions");
	}
    } else {
	P1(("Handler.Subscribe", "%O: someone (%O) tried to forcefully join us.\n", uni, context))
	sendmsg(context, PSYC.Packet("_notice_context_leave"));
    }

    return PSYC.Handler.STOP;
}

int filter(MMP.Packet p, mapping _v, mapping _m) {
    MMP.Uniform channel = p["_context"];

    // we have a check for that, messages without context never get here
    // if (!channel) return PSYC.Handler.GOON;

    mapping sub = string2uniform(_v["_subscriptions"], 1);
    // we could aswell save the object of that channel into the uniform.. 
    // they are some somewhat related (instead of cutting the string everytime)
    if (channel->channel) {
	MMP.Uniform context = uni->server->get_uniform(channel->super);

	if (!has_index(sub, channel) && SUBSCRIBED(sub[channel])) {
	    if (has_index(sub, context)) {
		P0(("Handler.Subscribe", "%O: %O forgot to join us into %O.\n", uni, context, channel))
	    } else {
		P0(("Handler.Subscribe", "%O: we never joined %O but are getting messages.\n", uni, channel))
	    }

	    sendmsg(channel, PSYC.Packet("_notice_context_leave_channel"));
	    return PSYC.Handler.STOP;
	}
    } else if (!has_index(sub, channel) && SUBSCRIBED(sub[channel])) {
	P0(("Handler.Subscribe", "%O: we never joined %O but are getting messages.\n", uni, channel))
	sendmsg(channel, PSYC.Packet("_notice_context_leave"));

	return PSYC.Handler.STOP;
    }

    return PSYC.Handler.GOON;
}

// ==================================

void subscribe(MMP.Uniform channel) {

    void callback1(string key, mixed value, MMP.Uniform channel) {

	void callback2(int error, string key, MMP.Uniform channel) {
	    
	    if (error) {
		P0(("Handler.Subscribe", "%O: set_unlock in subscribe failed. retry.\n", uni))
		// sigh!
		// retry ??
		uni->storage->unlock("_subscriptions", subscribe);
		call_out(subscribe, 4, channel);
		return;
	    }

	    // sending a request directly to a channel is like a recommendation for the
	    // context.
	    sendmsg(channel, PSYC.Packet("_request_context_enter_subscribe"));
	}; // CALLBACK

	MMP.Uniform context;

	if (key != "_subscriptions") {
	    P0(("Handler.Subscribe", "%O: got wrong data (%s instead of _subscriptions) from storage.", uni, key))
	    return;
	}

	if (channel->channel) {
	    context = uni->server->get_uniform(channel->super); 
	} else {
	    context = channel;
	}

	mixed sub = string2uniform(value, 1);

	if (has_index(sub, channel) && sub[channel]) { // REQUESTED or SUBSCRIBED
	    uni->storage->unlock("_subscriptions", callback2, channel);
	    return;
	}

	sub[channel] = REQUESTED(255);
	uni->storage->set_unlock("_subscriptions", sub, callback2, channel);
    }; // CALLBACK

    uni->storage->get_lock("_subscriptions", callback1, channel);
}

void unsubscribe(MMP.Uniform channel) {

    sendmsg(channel, PSYC.Packet("_request_context_leave_subscribe"));

    void callback (string key, mixed value, MMP.Uniform channel) {

	if (key != "_subscriptions") {
	    P0(("Handler.Subscribe", "%O: got wrong data (%s instead of _subscriptions) from storage.", uni, key))
	    return;
	}
	
	mapping sub = string2uniform(value, 1);

	MMP.Uniform context;
	if (channel->channel) {
	    context = uni->server->get_uniform(channel->super); 
	} else {
	    context = channel;
	}
	
	if (!has_index(sub, context)) {
	    uni->storage->unlock("_subscriptions");
	    if (channel == context) {
		sendmsg(context, PSYC.Packet("_request_context_leave"));
	    } else {
		sendmsg(context, PSYC.Packet("_request_context_leave_channel"));
	    }

	    return;
	}

	m_delete(sub, context); // forcefully delete it before we even told the other side??
	
	void callback2(int error, string key, MMP.Uniform context, MMP.Uniform channel) {

	    if (error) {
		P0(("Handler.Subscribe", "%O: set_unlock in unsubscribe failed. retry.\n", uni))
		uni->storage->unlock("_subscriptions");
		call_out(unsubscribe, 4, channel);
		return;
	    }


	};

	uni->storage->set_unlock("_subscriptions", sub, callback2, context, channel);
    };

    uni->storage->get_lock("_subscriptions", callback, channel);
}

