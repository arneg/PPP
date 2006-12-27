// vim:syntax=lpc
// psyc root object. does most routing, multicast signalling etc.
//
#include <debug.h>

inherit PSYC.Unl;

void create(MMP.Uniform uniform, object server, PSYC.Storage storage) {
    ::create(uniform, server, storage);
    PT(("PSYC.Root", "new PSYC.Root(%O, %O, %O)\n", uni, server, storage))

    add_handlers(Circuit(this));
}

class Circuit {

    inherit PSYC.Handler.Base;

    constant _ = ([
	"postfilter" : ([
	    "_notice_circuit_established" : 0,
	    "_status_circuit" : 0,
	]),
    ]);

    int postfilter_notice_circuit_established(MMP.Packet p, mapping _v, mapping _m) {
	// TODO: is a _source_identification valid here _at all_ ? doesnt make too much sense.
	server->add_route(p->source(), p->source()->handler->circuit);
	server->activate(p->source()->root);

	return PSYC.Handler.STOP;
    }

    int postfilter_status_circuit(MMP.Packet p, mapping _v, mapping _m) {
	server->activate(p->source());

	return PSYC.Handler.STOP;
    }

}

class Signaling {
    // basic, abstract routing functionality

    inherit PSYC.Handler.Base;
    int _init = 0;
    array init_callbacks = ({});

    constant _ = ([
	"_" : ([ "lock" : ({ "groups" }) ]),
	"postfilter" : ([
	    // someone entered the context and is supposed to get
	    // all messages on that context from us. this would
	    // in many cases be a local user, doesnt matter though
	    "_request_context_enter" : 0, 
#ifdef SUBSCRIBE
	    "_request_context_enter_subscribe" : ([ "lock" : ({ "groups" })]),
#endif
	    // same for leaving
	    "_request_context_leave" : 0, 
#ifdef SUBSCRIBE
	    "_request_context_leave_subscribe" : ([ "lock" : ({ "groups" })]),
#endif
	    // the context is empty. stop sending any messages. 
	    "_status_context_empty" : 0, 
	]),
    ]);

    int is_inited() {
	return _init;	
    }

    int init_cb_add(mixed ... args) {
	init_callbacks += ({ args });
    }

    int init(mapping _v, function callback) {

	int count;

	void _cb(int error, MMP.Uniform group, MMP.Uniform guy) {
	    if (!--count) {
		_init = 1;
		foreach (init_callbacks; ; mixed temp) {
		    temp[0](@temp[1..]);
		}
	    }

	    if (error) {
		P0(("PSYC.Root", "Insert failed for %O into %O.\n", guy, group))
	    }
	};
	
	foreach (_v["groups"]; MMP.Uniform group; mapping members) {
	    object context = uni->server->get_context(group);

	    count += sizeof(members);
	    foreach (members; MMP.Uniform guy; int d) {
		call_out(context->insert, 0, guy, _cb, group, guy);
	    }
	}

	if (!count) {
	    call_out(callback, 0, PSYC.Handler.GOON);
	} else {
	    init_cb_add(callback);
	}
    }

    int postfilter_request_context_enter(MMP.Packet p, mapping _v, mapping _m) {
	MMP.Uniform member = p["_source_relay"];
	PSYC.Packet t = p->data;
	if (!has_index(t->vars, "_group")) {
	    uni->sendmsg(p->source(), t->reply("_error_context_enter"));
	    return PSYC.Handler.STOP;
	}

	MMP.Uniform context = string2uniform(t["_group"]);

	uni->server->get_context(context)->insert(member);
	uni->sendmsg(p->source(), t->reply("_status_context_enter"));

	return PSYC.Handler.STOP;
    }

    int postfilter_status_context_enter_subscribe(MMP.Packet p, mapping _v, mapping _m) {
    }

    int postfilter_status_context_leave(MMP.Packet p, mapping _v, mapping _m) {
	MMP.Uniform member = p["_source_relay"];
	PSYC.Packet t = p->data;
	if (!has_index(t->vars, "_group")) {
	    uni->sendmsg(p->source(), t->reply("_error_context_leave"));
	    return PSYC.Handler.STOP;
	}

	MMP.Uniform context = string2uniform(t["_group"]);

	object c = uni->server->get_context(context);
	c->remove(member);

	if (!sizeof(c)) {
	    uni->server->unregister_context(context);
	    sendmsg(p->source(), PSYC.Packet("_status_context_empty", ([ "_group" : context ])));
	}

	sendmsg(p->source(), PSYC.Packet("_status_context_leave", ([ "_group" : context ])));
    }

    int postfilter_status_context_leave_subscribe(MMP.Packet p, mapping _v, mapping _m) {
    }

    int postfilter_status_context_empty(MMP.Packet p, mapping _v, mapping _m) {
	PSYC.Packet t = p->data;
	if (!has_index(t->vars, "_group")) {
	    uni->sendmsg(p->source(), t->reply("_error_context_empty"));
	    return PSYC.Handler.STOP;
	}

	MMP.Uniform context = string2uniform(t["_group"]);
    }


}

#if 0
void msg(MMP.Packet packet) {

    if (::msg(packet)) return;

    MMP.Uniform source = packet["_source"];

    P2(("PSYC.Server", "rootmsg(%O) from %O\n", packet, connection))
    if (packet->data) {
	PSYC.Packet message = packet->data;

	switch (message->mc) {
	    // ich weiss nichtmehr so genau. in FORK wird das eh alles
	    // anders.. ,)
	case "_notice_circuit_established":
	    server->add_route(source->host+" "+(string)(source->port||4404), connection);
	case "_status_circuit":
	    // auch hier nicht sicher
	    
	    source->handler->activate();
	    break;
	default:
	    return;
	}
    } else { // hmm

    }
}
#endif
