// vim:syntax=lpc

inherit PSYC.Handler.Base;

// A handler implementing all kinds of client features.. in here only those 
// that can be used with the standard api only (sendmsg)
//

constant _ = ([
    "postfilter" : ([
	"_request_do_tell" : 0,
	"_request_do_register" : 0,
    ]),
]);

int postfilter_request_do_tell(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;
   
    if (!_m["itsme"]) {
	sendmsg(p->source(), m->reply("_failure"+m->mc));	
	return PSYC.Handler.STOP;
    }

    if (MMP.is_uniform(m["_person"])) {
	sendmsg(m["_person"], PSYC.Packet("_message_private", 0, m->data));
    } else {
	sendmsg(p->source(), m->reply("_failure"+m->mc));
    }

    return PSYC.Handler.STOP;
}

int postfilter_request_do_register(MMP.Packet p, mapping _v, mapping _m) {

    if (!_m["itsme"]) {
	sendmsg(p->source(), m->reply("_failure"+m->mc));	
	return PSYC.Handler.STOP;
    }

    void callback(string key, int error) {
	if (error) {
	    sendmsg(p->source(), m->reply("_failure_register"));
	} else {
	    sendmsg(p->source(), m->reply("_notice_register"));
	}
    }

    if (has_index(m->vars, "_password") && stringp(m["_password"])) {
	parent->storage->set("_password", m["_password"], callback);
	parent->storage->save();
    } else {
	sendmsg(p->source(), m->reply("_failure_register"));
    }

    return PSYC.Handler.STOP;
}
