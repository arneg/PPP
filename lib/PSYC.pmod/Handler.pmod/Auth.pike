// vim:syntax=lpc

//! Handler implementing remote PSYC Authentication.
//! 
//! The handler filters all incoming packet that have @expr{_source_identification@}
//! set and asks that given uniform for authentification of the @expr{_source@}.
//! See the link for a detailed description of PSYC Authentication.
//! 
//! Requires no variables from storage whatsoever.
//! 
//! @seealso
//! 	http://about.psyc.eu/Authentication

inherit PSYC.Handler.Base;

constant _ = ([
    "filter" : ([
	"_notice_authentication" : 0,		      
	"_error_authentication" : 0,		      
	"" : ([ 
	    "async" : 1,
	    "check" : "has_identification",
	]),
    ]),
    "postfilter" : ([
	"_request_authentication" : 0,
	"_request_authenticate" : 0,
	"_request_authenticate_remove" : 0,
    ]),
]);

constant export = ({ "authenticate" });

mapping(MMP.Uniform:MMP.Uniform) unl2uni = ([ ]);
// we may have several people representing the same .. guy. they all want some
// piece of the cake
mapping(MMP.Uniform:MMP.Uniform|array(MMP.Uniform)) uni2unl = ([]);
mapping(MMP.Uniform:mapping(MMP.Uniform:array(function))) pending = ([ ]);
multiset(MMP.Uniform) authenticated = (<>);

void authenticate(MMP.Uniform t) {
    authenticated[t] = 1;
}

int postfilter_request_authenticate(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;

    if (!_m["itsme"]) {
	sendmsg(p->reply(), m->reply("_failure_invalid_request_authenticate"));
	return PSYC.Handler.STOP;
    }

    if (!has_index(m->vars, "_location") || !MMP.is_uniform(m["_location"])) {
	sendmsg(p->reply(), m->reply("_error_invalid_request_authenticate"));
	return PSYC.Handler.STOP;
    }

    authenticate(m["_location"]);

    return PSYC.Handler.STOP;
}

int postfilter_request_authenticate_remove(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;

    if (!_m["itsme"]) {
	sendmsg(p->reply(), m->reply("_failure_invalid_request_authenticate_remove"));
	return PSYC.Handler.STOP;
    }

    if (!has_index(m->vars, "_location") || !MMP.is_uniform(m["_location"])) {
	sendmsg(p->reply(), m->reply("_error_invalid_request_authenticate_remove"));
	return PSYC.Handler.STOP;
    }

    while (authenticated[m["_location"]]) { 
	authenticated[m["_location"]]--;
    }

    return PSYC.Handler.STOP;
}

void auth_reply(int s, MMP.Packet p) {
    PSYC.Packet m = p->data;

    if (s) {
	sendmsg(p->reply(), m->reply("_notice_authentication",
				       ([ "_location" : m["_location"] ]), 0));	
    } else {
	sendmsg(p->reply(), m->reply("_error_authentication",
				       ([ "_location" : m["_location"] ]), 0));	
    }
}

int postfilter_request_authentication(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;

    if (!has_index(m->vars, "_location")) {
	sendmsg(p->reply(), m->reply("_error_invalid_request_authentication"));
	return PSYC.Handler.STOP;
    }

    if (has_index(authenticated, m["_location"])) {
	call_out(auth_reply, 0, 1, p);
    } else parent->check_authentication(m["_location"], auth_reply, p);

    return PSYC.Handler.STOP;
}

int filter_error_authentication(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;

    if (!has_index(m->vars, "_location")) {
	debug("auth", 1, "incomplete _error_invalid_authentication (_location is missing)\n");
	return PSYC.Handler.STOP;
    }

    MMP.Uniform source = p["_source"];
    MMP.Uniform location = m["_location"];

    if (has_index(pending, location) && has_index(pending[location], source)) {
	m_delete(pending[location], source)(0);

	debug("auth", 1, "I was not able to get authentication for %s (claims to be %s).\n", location, source);

	PSYC.Packet failure = PSYC.Packet("_failure_authentification", ([ "_identification" : source ]));

	sendmsg(location, failure);
    } else {
	debug("auth", 1, "_error_authentication even though we never requested one.\n");
    }

    return PSYC.Handler.STOP;
}

int filter_notice_authentication(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;

    if (!has_index(m->vars, "_location")) {
	debug("auth", 0, "incomplete _notice_authentication (_location is missing)\n");
	return PSYC.Handler.STOP;
    }

    MMP.Uniform source = p["_source"];
    MMP.Uniform location = m["_location"];
    
    // we dont use that yet
    debug("auth", 1, "Successfully authenticated %s as %s.\n", location, source);
    unl2uni[location] = source; 	

    if (has_index(uni2unl, source)) {
	if (arrayp(uni2unl[source]))	
	    uni2unl[source] += ({ location }); 
	else
	    uni2unl[source] = ({ uni2unl[source], location });
    } else uni2unl[source] = location;

    if (has_index(pending, location) && has_index(pending[location], source)) {
	m_delete(pending[location], source)(PSYC.Handler.GOON);
	if (!sizeof(pending[location])) {
	    m_delete(pending, location);
	}
    }

    return PSYC.Handler.STOP;
}

int has_identification(MMP.Packet p, mapping _v) {
    return has_index(p->vars, "_source_identification") || has_index(p->vars, "_source_identification_reply");
}

void filter(MMP.Packet p, mapping _v, mapping _m, function cb) {

    // why are we not using send_tagged here???
    MMP.Uniform id = p["_source_identification"];	
    MMP.Uniform s = p["_source"];

    if (id == uni && _m["itsme"]) { // self auth
	call_out(cb, 0, PSYC.Handler.GOON);
	return;
    }

    if (!has_index(unl2uni, s) || (unl2uni[s] != id && m_delete(unl2uni, s))) {
	if (!has_index(pending, s)) {
	    pending[s] = ([]);
	}

	if (!has_index(pending[s], id)) {
	    pending[s][id] = ({  }); 
	    PSYC.Packet request = PSYC.Packet("_request_authentication",
					      ([ "_location" : s ]));
	    sendmsg(id, request);
	}

	pending[s][id] += ({ cb }); 
	return;
    }

    call_out(cb, 0, PSYC.Handler.GOON);
}
