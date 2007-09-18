// vim:syntax=lpc
#include <debug.h>

inherit PSYC.Handler.Base;

//! This handler provides entities with capabilities to be linked to.
//!
//! Expects @expr{parent@} to provide
//! @ul
//! 	@item
//! 		@expr{void attach(MMP.Uniform client)@}
//! 	@item
//! 		@expr{void detach(MMP.Uniform client)@}
//! 	@item
//! 		@expr{int(0..1) attached(MMP.Uniform client)@}
//! @endul
//!
//! Handles the following Message Classes
//! @ul
//! 	@item
//! 		@expr{_request_link@}
//! 	@item
//! 		@expr{_request_unlink@}
//! 	@item
//! 		@expr{_set_password@}
//! @endul
//! Also this handler will set @expr{"itsme"@} in the misc mapping to
//! @expr{1@} if the sender of an incoming packet is a linked client.
//!
//! Openheartedly uses the "password" storage variable.

constant _ = ([
    "init" : ({ "_password" }),
    "prefilter" : ([
	"" : 0,
    ]),
    "postfilter" : ([
	"_request_link" : ({ "password" }),
	"_request_unlink" : 0,
	"_set_password" : ({ "password" }),
	"_failure_delivery" : 0,
    ]),
]);

int init(mapping _v) {
    parent->isNewbie(!stringp(_v["password"]));

    set_inited(1);
}

int prefilter(MMP.Packet p, mapping _v, mapping _m) {
    MMP.Uniform source = p["_source"];
    
    if (parent->attached(source) || source == uni) {
	_m["itsme"] = 1;
    } else {
	_m["itsme"] = 0;
    }

    return PSYC.Handler.GOON;
}

int postfilter_failure_delivery(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;

    if (MMP.is_uniform(m["_location"]) && parent->attached(m["_location"])) {
	parent->detach(m["_location"]);
	PT(("Person", "%O unlinked from %O because of delivery_failure.", m["_location"], parent))
    }

    return PSYC.Handler.GOON;
}

int postfilter_request_link(MMP.Packet p, mapping _v, mapping _m) {

    PSYC.Packet m = p->data;
    MMP.Uniform source = p["_source"];

    if (stringp(_v["password"])) {
	if (!has_index(m->vars, "_password")) {
	    sendmsg(source, m->reply("_query_password"));
	    return PSYC.Handler.STOP;
	}

	P3(("PSYC.Handler.Link", "comparing %O and %O.\n", _v["password"], m->vars["_password"]))
	if (_v["password"] != m->vars["_password"]) {
	    sendmsg(source, m->reply("_error_invalid_password"));
	    return PSYC.Handler.STOP;
	}
    }

    PT(("Link", "_request_link with %O.\n", m->vars))

//#ifdef PRIMITIVE_CLIENT
    if (has_index(m->vars, "_type") && m["_type"] == "_assisted") {
	// TODO: this will add multiple handlers. not fatal, wont produce bugs. but we
	// need some way to check if some handler has been added already. same stuff
	// is needed for removal
	object o = PSYC.PrimitiveClient(([ 
					 "uniform" : parent->server->random_uniform("primitive"), 
					 "server" : parent->server, 
					 "person" : uni, 
					 "password" : stringp(_v["_password"]) && m["_password"], 
					 "client_uniform" : source,
					 ]));
	return PSYC.Handler.STOP;
    } else 
//#endif
	parent->attach(source);
    

    sendmsg(source, m->reply("_notice_link"));	
    return PSYC.Handler.STOP;
}

int postfilter_set_password(MMP.Packet p, mapping _v, mapping _m) {
    // rewrite!!
    return postfilter_request_link(p, _v, _m); 
}

int postfilter_request_unlink(MMP.Packet p, mapping _v, mapping _m) {

    parent->detach(p["_source"]);
    sendmsg(p["_source"], p->data->reply("_notice_unlink"));
    return PSYC.Handler.STOP;
}
