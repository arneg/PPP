// vim:syntax=lpc

inherit PSYC.Handler.Base;

constant _ = ([
    "postfilter" : ([
	"_request_execute" : 0,
	"_request_input" : 0,
    ]),
]);

int postfilter_request_execute(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;

    if (!_m["itsme"]) {
	sendmsg(p->source(), m->reply("_failure"+m->mc));
	return PSYC.Handler.STOP;
    }
    
    parent->attachee->cmd(m->data);
    return PSYC.Handler.STOP;
}

int postfilter_request_input(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;

    if (!_m["itsme"]) {
	sendmsg(p->source(), m->reply("_failure"+m->mc));
	return PSYC.Handler.STOP;
    }

    // ugly code here:
    if (m->data[0] == '/') {
	parent->attachee->cmd(m->data[1..]);
    } else if (has_index(m->vars, "_focus")) {
	MMP.Uniform target;

	if (stringp(m["_focus"])) {
	    target = parent->user_to_uniform(m["_focus"]);
	} else if (objectp(m["_focus"])) {
	    target = m["_focus"];
	}
	
	if (MMP.is_uniform(target)) {
	    PSYC.Packet packet;

	    if (MMP.is_place(target)) {
		packet = PSYC.Packet("_message_public", 0, m->data);
	    } else if (MMP.is_person(target)) {
		packet = PSYC.Packet("_message_private", 0, m->data);
	    } else {
		sendmsg(p->source(), m->reply("_failure"+m->mc));
		return PSYC.Handler.STOP;
	    }

	    sendmsg(target, packet);
	}
    }
   
    return PSYC.Handler.STOP;
}
