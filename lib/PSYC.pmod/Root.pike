// vim:syntax=lpc
// psyc root object. does most routing, multicast signalling etc.
//
#include <debug.h>

inherit PSYC.Unl;

void create(MMP.Uniform uniform, object server, object storage) {
    ::create(uniform, server, storage);
    P3(("PSYC.Root", "new PSYC.Root(%O, %O, %O)\n", parent, server, storage))

    add_handlers(Circuit(this, sendmmp, uni),
		 Signaling(this, sendmmp, uni));
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
    // TODO: move the storage stuff to the Context objects! it sux in this 
    // 	     place.

    inherit PSYC.Handler.Base;

    constant _ = ([
	"_" : ({ "groups" }),
	"postfilter" : ([
	    // someone entered the context and is supposed to get
	    // all messages on that context from us. this would
	    // in many cases be a local user, doesnt matter though
	    "_request_context_enter" : 0, 
	    "_request_context_leave" : 0, 
	    "_status_context_empty" : 0, 
	    "_notice_context_leave" : ([ "lock" : ({ "groups" }) ]), 
	    "_notice_context_enter_channel" : ([ "lock" : ({ "groups" }) ]), 
	]),
    ]);

    int init(mapping _v) {

	int count;

	void _cb(int error, MMP.Uniform group, MMP.Uniform guy) {
	    if (!--count) {
		set_inited(1);
	    }

	    if (error) {
		P0(("PSYC.Root", "Insert failed for %O into %O.\n", guy, group))
	    }
	};
	
	if (mappingp(_v["groups"])) {
	    foreach (_v["groups"]; MMP.Uniform group; mapping members) {
		object context = parent->server->get_context(group);

		count += sizeof(members);
		foreach (members; MMP.Uniform guy; int d) {
		    call_out(context->insert, 0, guy, _cb, group, guy);
		}
	    }
	} else {
	    parent->storage->set("groups", ([ ]));
	}

	if (!count) {
	    set_inited(1);
	}
    }

    // TODO: 
    // 	let the master enter someone to a channel
    // 	master here means a top router.
    int postfilter_request_context_enter(MMP.Packet p, mapping _v, mapping _m) {
	PSYC.Packet t = p->data;

	if (!(has_index(t->vars, "_group") && objectp(t["_group"]) 
	      && has_index(t->vars, "_supplicant") && objectp(t["_supplicant"]))) {
	    sendmsg(p->source(), t->reply("_error_context_enter"));
	    return PSYC.Handler.STOP;
	}

	MMP.Uniform member = t["_supplicant"];
	MMP.Uniform group = t["_group"];

	// TODO: this is a "security" check special to the way our signaling currently works,
	// e.g. with one hop. we have to set up something else to be able to have it work in
	// more complex settings. would make some kind of trust necessary
	if (p->source() != (member->is_local() ? member : member->root)) {
	    sendmsg(p->source(), t->reply("_error_context_enter_trust"));
	}

	MMP.Uniform target;

	if (group->is_local()) {
	    target = group;
	} else {
	    target = group->root;
	}

	if (target == uni) {
	    P0(("Root", "crazy in %O.\n", p))
	    return PSYC.Handler.STOP;
	}

	void callback(MMP.Packet reply, mapping _v) {
	    PSYC.Packet m = reply->data;
	    mapping groups = _v["groups"];

	    P0(("Root", "%O: reply to _request is %O.\n", parent, m))

	    if (PSYC.abbrev(m->mc, "_notice_context_enter")) {
		parent->server->get_context(group)->insert(member);
		if (!has_index(groups, group)) {
		    groups[group] = ([]);
		}
		groups[group][member] = 1;
		sendmsg(p->source(), t->reply("_notice_context_enter", ([ "_group" : group ])));
		parent->storage->set_unlock("groups", groups);
	    } else {
		sendmsg(p->source(), t->reply("_notice_context_discord", ([ "_group" : group ])));
		parent->storage->unlock("groups");
	    }
	    parent->storage->save();

	};


	send_tagged_v(target, PSYC.Packet("_request_context_enter", ([ "_group" : group, "_supplicant" : member ])), 
				    ([ "lock" : (< "groups" >) ]), callback);

	return PSYC.Handler.STOP;
    }

    // bottom up leave request. top down just sends a notice.. not politeness needed
    int postfilter_request_context_leave(MMP.Packet p, mapping _v, mapping _m) {
	PSYC.Packet t = p->data;

	if (!(has_index(t->vars, "_group") && objectp(t["_group"]) 
	      && has_index(t->vars, "_supplicant") && objectp(t["_supplicant"]))) {
	    sendmsg(p->source(), t->reply("_error_context_leave"));
	    return PSYC.Handler.STOP;
	}

	MMP.Uniform member = t["_supplicant"];
	MMP.Uniform group = t["_group"];

	if (p->source() != (member->is_local() ? member : member->root)) {
	    sendmsg(p->source(), t->reply("_error_context_leave_trust"));
	    return PSYC.Handler.STOP;
	}

	MMP.Uniform target;

	if (group->is_local()) {
	    target = group;
	} else {
	    target = group->root;
	}

	if (target == uni) {
	    P0(("Root", "crazy in %O.\n", p))
	    return PSYC.Handler.STOP;
	}

	object c = parent->server->get_context(group);

	void callback(MMP.Packet reply, mapping _v) {
	    PSYC.Packet m = reply->data;
	    mapping groups = _v["groups"];

	    P0(("Root", "%O: reply to _request is %O.\n", parent, m))

	    if (c->contains(member)) {
		c->remove(member);

		if (!has_index(groups, group)) {
		    P0(("Root", "inconsistency of storage and context.\n"))
		    parent->storage->unlock("groups");
		} else {
		    if (has_index(groups[group], member)) {
			m_delete(groups[group], member);
			parent->storage->set_unlock("groups", groups);
		    } else {
			parent->storage->unlock("groups");
		    }
		}
		parent->storage->save();
	    }

	    sendmsg(p->source(), t->reply("_notice_context_leave", ([ "_group" : group, "_supplicant" : member ])));
	};

	if (!c->contains(member)) {
	    sendmsg(p->source(), t->reply("_notice_context_leave", ([ "_group" : group, "_supplicant" : member ]))); 
	    return PSYC.Handler.STOP;
	}

	send_tagged_v(target, PSYC.Packet("_request_context_leave", ([ "_group" : group, "_supplicant" : member ])), 
				    ([ "lock" : (< "groups" >) ]), callback);

	return PSYC.Handler.STOP;
    }

    // master kicks someone out.
    int postfilter_notice_context_leave(MMP.Packet p, mapping _v, mapping _m) {
	PSYC.Packet m = p->data;	
	MMP.Uniform member = m["_supplicant"];
	MMP.Uniform channel = m["_group"];

	if (!objectp(member) || !objectp(channel)) {
	    sendmsg(p->source(), m->reply("_error_context_enter_channel"));
	    parent->storage->unlock("groups");
	    return PSYC.Handler.STOP;
	}

	if (p->source() != (channel->is_local() 
			    ? (channel->channel ? channel->super : channel) 
			    : channel->root)) {
	    P1(("Root", "%O: Got channel leave for context %O from %O. denied.\n", uni, channel, p->source()))
	    // TODO: fix the mc here.. depending on the incoming one
	    sendmsg(p->source(), m->reply("_error_context_leave"));
	    parent->storage->unlock("groups");
	    return PSYC.Handler.STOP;
	}

	object c = parent->server->get_context(channel);

	if (!c->contains(member)) {
	    sendmsg(p->source(), m->reply("_error_context_enter_channel"));
	    parent->storage->unlock("groups");
	    return PSYC.Handler.STOP;
	}

	mapping groups = _v["groups"];

	c->remove(member);
	
	if (!has_index(groups, channel)) {
	    P0(("Root", "inconsistency of storage and context.\n"))
	    parent->storage->unlock("groups");
	     
	    return PSYC.Handler.STOP;
	}

	MMP.Uniform target;
	if (member->is_local()) {
	    target = member; 
	} else {
	    target = member->root;
	}
	
	sendmsg(target, m);
	m_delete(groups[channel], member);
	parent->storage->set_unlock("groups", groups);
	parent->storage->save();
	return PSYC.Handler.STOP;
    }

    // master puts someone into a channel
    int postfilter_notice_context_enter_channel(MMP.Packet p, mapping _v, mapping _m) {
	PSYC.Packet m = p->data;	
	MMP.Uniform member = m["_supplicant"];
	MMP.Uniform channel = m["_group"];

	if (!objectp(member) || !objectp(channel)) {
	    sendmsg(p->source(), m->reply("_error_context_enter_channel"));

	    parent->storage->unlock("groups");
	    return PSYC.Handler.STOP;
	}

	if (!channel->super) {
	    // be more specific here
	    P1(("Root", "%O: got channel join from %O for a non-channel (%O).\n", uni, p->source(), channel))
	    sendmsg(p->source(), m->reply("_error_context_enter_channel"));
	    parent->storage->unlock("groups");
	    return PSYC.Handler.STOP;
	}

	if (p->source() != (channel->is_local() ? channel->super : channel->root)) {
	    P1(("Root", "%O: Got channel join to %O from context %O. denied.\n", uni, channel, p->source()))
	    sendmsg(p->source(), m->reply("_error_context_enter_channel"));
	    parent->storage->unlock("groups");
	    return PSYC.Handler.STOP;
	}

	object c = parent->server->get_context(channel->super);

	if (!c->contains(member)) {
	    sendmsg(p->source(), m->reply("_error_context_enter_channel"));
	    parent->storage->unlock("groups");
	    return PSYC.Handler.STOP;
	}

	c = parent->server->get_context(channel);

	if (c->contains(member)) {
	    // all is fine.
	    P1(("Root", "%O: %O tries to double join %O into %O.\n", uni, p->source(), member, channel))
	    parent->storage->unlock("groups");
	    return PSYC.Handler.STOP;
	}

	MMP.Uniform target;
	if (member->is_local()) {
	    target = member; 
	} else {
	    target = member->root;
	}
	// TODO: check for mappingp(_v["groups"])
	mapping groups = _v["groups"];

	if (!has_index(groups, channel)) {
	    groups[channel] = ([]);
	}

	groups[channel][member] = 1;
	c->insert(member);
	sendmsg(target, m);
	parent->storage->set_unlock("groups", groups);
	parent->storage->save();
	return PSYC.Handler.STOP;
    }

    int postfilter_status_context_empty(MMP.Packet p, mapping _v, mapping _m) {
	PSYC.Packet t = p->data;
	if (!has_index(t->vars, "_group")) {
	    sendmsg(p->source(), t->reply("_error_context_empty"));
	    return PSYC.Handler.STOP;
	}

	MMP.Uniform context = t["_group"];
    }


}

