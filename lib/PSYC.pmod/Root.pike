// vim:syntax=lpc
// psyc root object. does most routing, multicast signalling etc.
//

inherit PSYC.Unl;

void create(mapping params) {
    ::create(params);

    mapping handler_params = params + ([ "parent" : this, "sendmmp" : sendmmp ]);

    add_handlers(
		 Circuit(handler_params),
		 Signaling(handler_params),
    );
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
	"init" : ({ "groups" }),
	"postfilter" : ([
	    // someone entered the context and is supposed to get
	    // all messages on that context from us. this would
	    // in many cases be a local user, doesnt matter though
	    "_request_context_enter" : 0, 
	    //"_request_context_leave" : 0, 
	    "_status_context_empty" : 0, 
	    "_notice_context_leave" : ([ "lock" : ({ "groups" }) ]), 
	    "_request_context_leave" : ([ "lock" : ({ "groups" }) ]), 
	    "_notice_context_enter_channel" : ([ "lock" : ({ "groups" }) ]), 
	]),
    ]);

    int(0..1) zero_and_zero_only(mixed zero) {
	if (0 == zero) return !zero_type(zero);
	return 0;
    };


    int init(mapping _v) {

	int count;

	void _cb(int error, MMP.Uniform group, MMP.Uniform guy) {
	    if (!--count) {
		set_inited(1);
	    }

	    if (error) {
		debug(([ "storage" : 0, "multicast_routing" : 0 ]), "Insert failed for %O into %O.\n", guy, group);
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
	    return PSYC.Handler.STOP;
	}

	MMP.Uniform target;

	if (group->is_local()) {
	    target = group;
	} else {
	    target = group->root;
	}

	if (target == uni) {
	    debug(([ "multicast_routing" : 2, "protocol_error" : 2 ]), "%O is trying to the root.\n", p->source());
	    return PSYC.Handler.STOP;
	}

	int callback(MMP.Packet reply, mapping _v) {
	    PSYC.Packet m = reply->data;
	    mapping groups = _v["groups"];

	    if (PSYC.abbrev(m->mc, "_notice_context_enter")) {
		parent->server->get_context(group)->insert(member);
		if (!has_index(groups, group)) {
		    groups[group] = ([]);
		}
		groups[group][member] = 1;
		sendmsg(p->source(), t->reply("_notice_context_enter", ([ "_group" : group, "_supplicant" : member ])));
		parent->storage->set_unlock("groups", groups);
	    } else {
		sendmsg(p->source(), t->reply("_notice_context_discord", ([ "_group" : group, "_supplicant" : member ])));
		parent->storage->unlock("groups");
	    }
	    parent->storage->save();

	    return PSYC.Handler.STOP;
	};


	send_tagged_v(target, PSYC.Packet("_request_context_enter", ([ "_group" : group, "_supplicant" : member ])), 
				    ([ "lock" : (< "groups" >) ]), callback);

	return PSYC.Handler.STOP;
    }

    // master kicks someone out.
    int postfilter_notice_context_leave(MMP.Packet p, mapping _v, mapping _m) {
	PSYC.Packet m = p->data;	
	MMP.Uniform member = m["_supplicant"];
	MMP.Uniform channel = m["_group"];
	MMP.Uniform target; // who gets the _notice??

	debug("temp", 0, "packet: %O, vars: %O\n", p, m->vars);
	debug("multicast_routing", 0, "_notice_context_leave of %O in channel %O.\n", member, channel);

	if (!objectp(member) || !objectp(channel)) {
	    sendmsg(p->source(), m->reply("_error_context_enter_channel"));
	    parent->storage->unlock("groups");
	    return PSYC.Handler.STOP;
	}

	if (p->source() == (channel->is_local() 
			    ? (channel->channel ? channel->super : channel) 
			    : channel->root)) {
	    // TOP_DOWN
	    debug("multicast_routing", 4, "TOP-DOWN leave!\n");
	    target = member->is_local() ? member : member->root;
	} else {
	    debug(([ "multicast_routing" : 2, "protocol_error" : 2 ]), 
		  "%O: Got channel leave for context %O from %O. denied.\n", uni, channel, p->source());
	    // TODO: fix the mc here.. depending on the incoming one
	    sendmsg(p->source(), m->reply("_error_context_leave"));
	    parent->storage->unlock("groups");
	    return PSYC.Handler.STOP;
	}

	object c = parent->server->get_context(channel);

	if (zero_and_zero_only(member->is_local()) && !c->contains(member)) {
	    debug(([ "multicast_routing" : 0, "protocol_error" : 0 ]), "out of sync. %O not member of %O.\n", member, channel);
	} else {
	    c->remove(member);
	}

	mapping groups = _v["groups"];

	if (!has_index(groups, channel)) {
	    debug(([ "storage" : 0, "multicast_routing" : 0 ]), "inconsistency of storage and context.\n");
	    parent->storage->unlock("groups");
	} else {
	    m_delete(groups[channel], member);
	    parent->storage->set_unlock("groups", groups);
	    parent->storage->save();
	}

	sendmsg(target, m);
	return PSYC.Handler.STOP;
    }

    // user leaves himself.
    int postfilter_request_context_leave(MMP.Packet p, mapping _v, mapping _m) {
	PSYC.Packet m = p->data;	
	MMP.Uniform member = m["_supplicant"];
	MMP.Uniform channel = m["_group"];
	MMP.Uniform target; // who gets the _notice??

	debug("multicast_routing", 4, "_request_context_leave of %O in channel %O.\n", member, channel);

	if (!objectp(member) || !objectp(channel)) {
	    sendmsg(p->source(), m->reply("_error_context_enter_channel"));
	    parent->storage->unlock("groups");
	    return PSYC.Handler.STOP;
	}

	if (p->source() == (member->is_local() ? member : member->root)) {
	    // BOTTOM_UP
	    debug("multicast_routing", 4, "BOTTOM-UP leave!\n");
	    target = channel->is_local() ? (channel->channel ? channel->super : channel) : channel->root;
	} else {
	    debug(([ "multicast_routing" : 2, "protocol_error" : 2 ]), 
		  "%O: Got channel leave for context %O from %O. denied.\n", uni, channel, p->source());
	    // TODO: fix the mc here.. depending on the incoming one
	    sendmsg(p->source(), m->reply("_error_context_leave"));
	    parent->storage->unlock("groups");
	    return PSYC.Handler.STOP;
	}

	object c = parent->server->get_context(channel);

	if (zero_and_zero_only(member->is_local()) && !c->contains(member)) {
	    debug(([ "multicast_routing" : 0, "protocol_error" : 0 ]), "out of sync. %O not member of %O.\n", member, channel);
	} else {
	    c->remove(member);
	}

	mapping groups = _v["groups"];

	if (!has_index(groups, channel)) {
	    debug(([ "storage" : 0, "multicast_routing" : 0 ]), "inconsistency of storage and context.\n");
	    parent->storage->unlock("groups");
	} else {
	    m_delete(groups[channel], member);
	    parent->storage->set_unlock("groups", groups);
	    parent->storage->save();
	}

	sendmsg(target, m);
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
	    debug(([ "multicast_routing" : 0, "protocol_error" : 0 ]), 
		  "%O: got channel join from %O for a non-channel (%O).\n", uni, p->source(), channel);
	    sendmsg(p->source(), m->reply("_error_context_enter_channel"));
	    parent->storage->unlock("groups");
	    return PSYC.Handler.STOP;
	}

	if (p->source() != (channel->is_local() ? channel->super : channel->root)) { // TODO:: needs zero_and_zero_only around is_local?
	    debug("multicast_routing", 1, "%O: Got channel join to %O from context %O. denied.\n", uni, channel, p->source());
	    sendmsg(p->source(), m->reply("_error_context_enter_channel"));
	    parent->storage->unlock("groups");
	    return PSYC.Handler.STOP;
	}

	object c = parent->server->get_context(channel->super);

	if (member->is_local() && !c->contains(member)) {
	    sendmsg(p->source(), m->reply("_error_context_enter_channel"));
	    debug("multicast_routing", 1, "%O: %O tries to force-join %O into %O.\n", p->source(), member, channel);
	    parent->storage->unlock("groups");
	    return PSYC.Handler.STOP;
	}

	c = parent->server->get_context(channel);

	if (member->is_local() && c->contains(member)) {
	    // all is fine.
	    debug("multicast_routing", 2, "%O: %O tries to double join %O into %O.\n", uni, p->source(), member, channel);
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

