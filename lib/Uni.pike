// vim:syntax=lpc
// TODO: this one should check for the authentication of
// _source_identification
// a simple class inherited by everyone having an address..
//
//
#include <debug.h>

object server;
string uni;

mapping(string:mixed) unl2uni = ([ ]);
// we may have several people representing the same .. guy. they all want some
// piece of the cake
mapping(string:string|array(string)) uni2unl = ([]);
mapping(string:mapping(string:string)) pending = ([ ]);

// _tag & _reply mechanism.. 
/*private :)*/ mapping(string:array(mixed)) _tags = ([]);

mixed cast(string type) {
    if (type == "string") return sprintf("Uni(%s)", qName());
}

string qName() {
    return uni;
}

// TODO: maybe we should use some proper random-string generation...
// maybe collect entropy by the action of users, which should be 
// pretty good in most applications. thats good for all the crypto
// stuff too
//
string send_tagged(string|PSYC.uniform target, PSYC.psyc_p m, 
		   function|void callback, mixed ... args) {
    string tag = random_string(8); // have a define for the length? 
   // am i paranoid?
   // I will not check here for has_index(_tags, tag).. those deterministic
   // random generators have periods of more than 2^32.. or something.
   //
    m["_tag"] = tag;

    if (callback)
	_tags[tag] = ({ callback, args });
    else 
	_tags[tag] = 0;
    
    send(target, m);
    return tag;
}

void append_arguments(string tag, mixed ... args) {
    // this one results in one more call of the callback with args
    //
    // i expect everyone to check for _tags[tag] before
    _tags[tag][1] += args;
}

void create(string u, object s) {
    uni = u;
    server = s;
}

// mixed target for objects?? i dont like something about that. even though
// we would have one more hashlookup
void sendmsg(string|PSYC.uniform target, string mc, string|void data, 
	     mapping|void vars) {
    send(target, PSYC.psyc_p(mc, data, vars));
}

void send(string|PSYC.uniform target, PSYC.psyc_p p) {

    P3(("Uni", "send(%O, %s)\n", target, p))

    if (has_index(uni2unl, (string)target)) {
	if (arrayp(uni2unl[(string)target])) {
	    foreach (uni2unl[(string)target], string t) {
		// we even need a _target_identification
		server->unicast(t, uni, p);
	    }
	    return;
	} else target = uni2unl[(string)target];
    }
    server->unicast(target, uni, p);	
}

void _auth_msg(MMP.mmp_p reply, MMP.mmp_p ... packets) {

    PSYC.psyc_p m = reply->data;

    if (objectp(m)) switch(m->mc) {
    case "_notice_authentication":
    case "_notice_authenticate":
    {
	int level = (int)m["_authentication_level"];
	string source = (string)reply["_source"];
	// we dont use that yet
	P2(("Uni", "Successfully authenticated %s as %s.\n", m["_location"], 
	    reply["_source"]))
	unl2uni[m["_location"]] = source; 	

	if (has_index(uni2unl, source)) {
	    if (arrayp(uni2unl[source]))	
		uni2unl[source] += ({ m["_location"] }); 
	    else
		uni2unl[source] = ({ uni2unl[source], m["_location"] });
	} else uni2unl[source] = m["_location"];

	foreach (packets, MMP.mmp_p p) {
	    msg(p);
	}
	break;
    }
    case "_error_invalid_authentication":
    {
	P2(("Uni", "I was not able to get authentication for %s (claims to be %s).\n", m["_location"], m["_identification"]))
	foreach (packets, MMP.mmp_p p) {
	    send(p["_source"], 
		 PSYC.psyc_p("_failure_authentication", 
		   "I was not able to authenticate you as [_identification].", 
		   ([ "_identification" : p["_source_identification"] ])));
	}
	break;
    }
    default:
	P0(("Uni", "I got an reply to _request_authentication i dont understand. method: %s.\n", m->mc))
    } else {
	P0(("Uni", "Got strange reply to an _request_authentication (no parsed psyc packet inside) from %s\n.", reply["_source"]))
    }
}

int msg(MMP.mmp_p p) {
    // check if _identification is valid
    string|PSYC.uniform source = p["_source"];

    // maybe its generally not a good idea to replace _source with
    // _source_identification ..
    //
    // we have a problem here, if someone authenticates himself using his
    // location having an _source_identification in the answer.. this will
    // trigger a new request for authentication.. naturally. so this must 
    // not happen.

    if (has_index(p, "_source_identification")) {
	string|PSYC.uniform id = p["_source_identification"];	
	string s = (string)source;

	if (!has_index(unl2uni, s)) {
	    if (has_index(pending, s) && 
		has_index(pending[s], (string)id)) {
		append_arguments(pending[s][(string)id], p);
	    } else {
		PSYC.psyc_p request = PSYC.psyc_p("_request_authentication",
						  "nil", 
						  ([ "_location" : source ]));
		pending[s] 
		    = ([ (string)id : send_tagged(id, request, 
						  _auth_msg, p) ]);
	    }
	    return 0;
	// TODO: think about caching failures.. 
#if 0
	} else if (0 == unl2uni[s]) {
	    // just dropping packets is evil.. but always replying is evil too.
	    // also the unl may want to identify as some other uni.. 
	    // TODO
#endif 
	} else if (unl2uni[s] != (string)id) {
	    m_delete(unl2uni, s);
	    return msg(p);
	} else { // everything is okay
	    p["_source"] = id;
	    p["_source_technical"] = source;
	}
    }

    if (objectp(p->data) && has_index(p->data, "_tag_reply")) {
	string reply = p->data["_tag_reply"];

	if (has_index(_tags, reply)) {
	    if (_tags[reply]) {
		function f = _tags[reply][0];
		mixed arg = _tags[reply][1];

		f(p, @arg);
		return 1;
	    }

	    m_delete(_tags, reply);
	} else {
	    P0(("Uni", "Received a fake (at least wrong) tag in a reply from %s.\n", source))
	}
    }

    return 0;
}
