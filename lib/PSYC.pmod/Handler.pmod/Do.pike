// vim:syntax=lpc

#include <debug.h>
inherit PSYC.Handler.Base;

// A handler implementing all kinds of client features.. in here only those 
// that can be used with the standard api only (sendmsg)
//

constant _ = ([
    "postfilter" : ([
	"_request_do_tell" : ([ "check" : "itsme" ]),
	"_request_do_say" : ([ "check" : "itsme" ]),
	"_request_do_register" : ([ "check" : "itsme" ]),
	"_request_do_enter" : ([ "check" : "itsme" ]),
	"_request_do_leave" : ([ "check" : "itsme" ]),
    ]),
]);

int itsme(MMP.Packet p, mapping _m) {
    PSYC.Packet m = p->data;

    if (!_m["itsme"]) {
	sendmsg(p->source(), m->reply("_failure_authentication"));	
	return PSYC.Handler.STOP;
    }

    return PSYC.Handler.GOON;
}

int postfilter_request_do_tell(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;

    if (MMP.is_person(m["_person"])) {
	sendmsg(m["_person"], PSYC.Packet("_message_private", 0, m->data));
    } else {
	sendmsg(p->source(), m->reply("_failure"+m->mc));
    }

    return PSYC.Handler.STOP;
}

int postfilter_request_do_say(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;

    if (MMP.is_place(m["_group"])) {
	sendmsg(m["_group"], PSYC.Packet("_message_public", 0, m->data));
    } else {
	sendmsg(p->source(), m->reply("_failure"+m->mc));
    }

    return PSYC.Handler.STOP;
}

int postfilter_request_do_register(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;

    void callback(string key, int error) {
	if (error) {
	    sendmsg(p->source(), m->reply("_failure_register"));
	} else {
	    sendmsg(p->source(), m->reply("_notice_register"));
	}
    };

    if (has_index(m->vars, "_password") && stringp(m["_password"])) {
	parent->storage->set("_password", m["_password"], callback);
	parent->storage->save();
    } else {
	sendmsg(p->source(), m->reply("_failure_register"));
    }

    return PSYC.Handler.STOP;
}

int postfilter_request_do_enter(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;
    
    if (MMP.is_place(m["_group"])) {
	PT(("Do", "%O is place.\n", m["_group"]))
	parent->subscribe(m["_group"]);
    } else {
	PT(("Do", "%O is no place.\n", m["_group"]))
	sendmsg(p->source(), m->reply("_failure"+m->mc));
    }
}

int postfilter_request_do_leave(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;

    if (MMP.is_place(m["_group"])) {
	sendmsg(p->source(), PSYC.Packet("_notice_leave", ([ "_group" : m["_group"] ])));
    } else {
	sendmsg(p->source(), m->reply("_failure"+m->mc));
    }
}
