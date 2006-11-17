/ vim:syntax=lpc
#include <debug.h>

inherit PSYC.Handler.Base;

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

int postfilter_notice_context_enter_channel(MMP.Packet p, mapping _v, mapping _m) {
    MMP.Uniform channel = p["_source"];

    if (channel->channel) {
	MMP.Uniform context = uni->server->get_uniform(channel->super);

	if (has_index(requested, context)) {
	    contexts[channel] = 1;
	} else {
	    P1(("Handler.Subscribe", "%O: someone (%O) tried to forcefully join us into his channel (%O).\n", uni, context, channel))
	    uni->sendmsg(channel, PSYC.Packet("_notice_context_leave_channel"));
	}
    } else {
	P0(("Handler.Subscribe", "%O: got _notice_context_enter_channel from non-channel (%O).\n", uni, channel))
	uni->sendmsg(channel, PSYC.Packet("_notice_context_leave"));
    }

    return PSYC.Handler.STOP;
}

int postfilter_notice_context_enter(MMP.Packet p, mapping _v, mapping _m) {
    MMP.Uniform context = p["_source"];

    if (context->channel) {
	P0(("Handler.Subscribe", "%O: _notice_context_enter from a channel (%O)!!!\n", context))	
    } else {
	if (has_index(requested, context)) {
	    P3(("Handler.Subscribe", "%O: joined a context (%O).\n", uni, context))
	    context[context] = 1;
	} else {
	    P1(("Handler.Subscribe", "%O: someone (%O) tried to forcefully join us.\n", uni, context))
	    uni->sendmsg(channel, PSYC.Packet("_notice_context_leave"));
	}
    }

    return PSYC.Handler.STOP;
}

int filter(MMP.Packet p, mapping _v, mapping _m) {
    MMP.Uniform channel = p["_context"];

    // we could aswell save the object of that channel into the uniform.. 
    // they are some somewhat related (instead of cutting the string everytime)
    if (channel->channel) {
	MMP.Uniform context = uni->server->get_uniform(channel->super);

	if (!has_index(contexts, channel)) {
	    if (has_index(contexts, context)) {
		P0(("Handler.Subscribe", "%O: %O forgot to join us into %O.\n", uni, context, channel))
	    } else {
		P0(("Handler.Subscribe", "%O: we never joined %O but are getting messages.\n", uni, channel))
	    }

	    uni->sendmsg(channel, PSYC.Packet("_notice_context_leave_channel"));
	    return PSYC.Handler.STOP;
	}
    } else if (!has_index(contexts, channel)) {
	P0(("Handler.Subscribe", "%O: we never joined %O but are getting messages.\n", uni, channel))
	uni->sendmsg(channel, PSYC.Packet("_notice_context_leave"));

	return PSYC.Handler.STOP;
    }

    return PSYC.Handler.GOON;
}

// ==================================

void subscribe(MMP.Uniform channel) {

    if (channel->channel) {
	requested[uni->server->get_uniform(channel->super)] = 1;
    } else {
	requested[channel] = 1;
    }

    // sending a request directly to a channel is like a recommendation for the
    // context.
    uni->sendmsg(channel, PSYC.Packet("_request_context_enter_subscribe"));
}

void unsubscribe(MMP.Uniform channel) {

    while (has_index(requested, channel)) { requested[channel]--; }

    uni->sendmsg(channel, PSYC.Packet("_request_context_leave_subscribe"));
}

void enter(MMP.Uniform channel) {
    requested[channel] = 1;

    if (channel->channel) {
	requested[uni->server->get_uniform(channel->super)] = 1;
    }

    uni->sendmsg(channel, PSYC.Packet("_request_context_enter"));
}

void leave(MMP.Uniform channel) {
    // TODO: dont you stop here.. remember: ASYNC STORAGE NEEDS LOCKS!!!

}

