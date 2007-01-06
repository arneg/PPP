// vim:syntax=lpc
// psyc root object. does most routing, multicast signalling etc.
//
#include <debug.h>

inherit PSYC.Unl;

void create(MMP.Uniform uniform, object server, object storage) {
    ::create(uniform, server, storage);
    P3(("PSYC.Root", "new PSYC.Root(%O, %O, %O)\n", uni, server, storage))

    add_handlers(Circuit(this),
		 Signaling(this));
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
	if (p->source()->handler) {
	    server->add_route(p->source(), p->source()->handler->circuit);
	}
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
    int _init = 1;
    array init_callbacks = ({});

    constant _ = ([
	"_" : ({ "groups" }),
	"postfilter" : ([
	    // someone entered the context and is supposed to get
	    // all messages on that context from us. this would
	    // in many cases be a local user, doesnt matter though
	    "_request_context_enter" : 0, 
	    "_request_context_leave" : 0, 
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
	PSYC.Packet t = p->data;

	if (!(has_index(t->vars, "_group") && objectp(t["_group"]) 
	      && has_index(t->vars, "_supplicant") && objectp(t["_supplicant"]))) {
	    uni->sendmsg(p->source(), t->reply("_error_context_enter"));
	    return PSYC.Handler.STOP;
	}

	MMP.Uniform member = t["_supplicant"];
	MMP.Uniform group = t["_group"];

	void callback(MMP.Packet reply, mapping _v) {
	    PSYC.Packet m = reply->data;
	    mapping groups = _v["_groups"];

	    if (PSYC.abbrev(m->mc, "_notice_context_enter")) {
		uni->server->get_context(group)->insert(member);
		if (!has_index(groups, group)) {
		    groups[group] = ([]);
		}
		groups[group][member] = 1;
		uni->sendmsg(p->source(), t->reply("_notice_context_enter"));
		uni->storage->set_unlock("_groups", groups);
	    } else {
		uni->sendmsg(p->source(), t->reply("_notice_context_enter"));
		uni->storage->unlock("_groups");
	    }

	};

	MMP.Uniform target = group->is_local() ? group : group->root;

	if (target == uni->uni) {
	    P0(("Root", "crazy in %O.\n", p))
	    return PSYC.Handler.STOP;
	}

	server->root->send_tagged_v(target, PSYC.Packet("_request_context_enter", ([ "_group" : group, "_supplicant" : member ])), 
				    ([ "lock" : (< "_groups" >) ]), callback);

	return PSYC.Handler.STOP;
    }

    int postfilter_request_context_leave(MMP.Packet p, mapping _v, mapping _m) {
	MMP.Uniform member = p["_source_relay"];
	PSYC.Packet t = p->data;
	if (!has_index(t->vars, "_group")) {
	    uni->sendmsg(p->source(), t->reply("_error_context_leave"));
	    return PSYC.Handler.STOP;
	}

	MMP.Uniform context = t["_group"];

	object c = uni->server->get_context(context);
	c->remove(member);

	if (!sizeof(c)) {
	    uni->server->unregister_context(context);
	    sendmsg(p->source(), PSYC.Packet("_status_context_empty", ([ "_group" : context ])));
	}

	sendmsg(p->source(), PSYC.Packet("_status_context_leave", ([ "_group" : context ])));
    }

    int postfilter_status_context_empty(MMP.Packet p, mapping _v, mapping _m) {
	PSYC.Packet t = p->data;
	if (!has_index(t->vars, "_group")) {
	    uni->sendmsg(p->source(), t->reply("_error_context_empty"));
	    return PSYC.Handler.STOP;
	}

	MMP.Uniform context = t["_group"];
    }


}

