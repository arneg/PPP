// vim:syntax=lpc
// TODO: this one should check for the authentication of
// _source_identification
// a simple class inherited by everyone having an address..
//
//
#include <debug.h>

function sendmmp;
object server;
MMP.Uniform uni;

mapping(MMP.Uniform:MMP.Uniform) unl2uni = ([ ]);
// we may have several people representing the same .. guy. they all want some
// piece of the cake
mapping(MMP.Uniform:MMP.Uniform|array(MMP.Uniform)) uni2unl = ([]);
mapping(MMP.Uniform:mapping(MMP.Uniform:string)) pending = ([ ]);

// _tag & _reply mechanism.. 
/*private :)*/ mapping(string:array(mixed)) _tags = ([]);

mixed cast(string type) {
    if (type == "string") return sprintf("Uni(%s)", qName());
}

MMP.Uniform qName() {
    return uni;
}

// TODO: maybe we should use some proper random-string generation...
// maybe collect entropy by the action of users, which should be 
// pretty good in most applications. thats good for all the crypto
// stuff too
//
string send_tagged(MMP.Uniform target, PSYC.Packet m, 
		   function|void callback, mixed ... args) {
    string tag;
    // have a define for the length? 
    while (has_index(_tags, tag = random_string(8))); 
    m["_tag"] = tag;

    if (callback)
	_tags[tag] = ({ callback, args });
    else 
	_tags[tag] = 0;
    
    sendmmp(target, m);
    return tag;
}

void append_arguments(string tag, mixed ... args) {
    // this one results in one more call of the callback with args
    //
    // i expect everyone to check for _tags[tag] before
    _tags[tag][1] += args;
}

void create(MMP.Uniform u, object s) {
    uni = u;
    server = s;
    sendmmp = server->deliver;
}

void sendmsg(MMP.Uniform target, PSYC.Packet m) {
    P3(("Uni", "sendmsg(%O, %O)\n", target, p))
    MMP.Packet p = MMP.Packet(m, 
			  ([ "_source" : uni,
			     "_target" : target ]));
    sendmmp(target, p);    
}

void _auth_msg(MMP.Packet reply, MMP.Packet ... packets) {

    PSYC.Packet m = reply->data;

    if (objectp(m)) switch(m->mc) {
    case "_notice_authentication":
    case "_notice_authenticate":
    {
	int level = (int)m["_authentication_level"];
	MMP.Uniform source = reply["_source"];
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

	foreach (packets, MMP.Packet p) {
	    msg(p);
	}
	break;
    }
    case "_error_invalid_authentication":
    {
	P2(("Uni", "I was not able to get authentication for %s (claims to be %s).\n", m["_location"], m["_identification"]))
	foreach (packets, MMP.Packet p) {
	    sendmmp(p["_source"], 
		 PSYC.Packet("_failure_authentication", 
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

int msg(MMP.Packet p) {
    // check if _identification is valid
    MMP.Uniform source = p["_source"];

    // maybe its generally not a good idea to replace _source with
    // _source_identification ..
    //
    // we have a problem here, if someone authenticates himself using his
    // location having an _source_identification in the answer.. this will
    // trigger a new request for authentication.. naturally. so this must 
    // not happen.

    if (has_index(p, "_source_identification")) {
	MMP.Uniform id = p["_source_identification"];	
	MMP.Uniform s = source;

	if (!has_index(unl2uni, s)) {
	    if (has_index(pending, s) && 
		has_index(pending[s], id)) {
		append_arguments(pending[s][id], p);
	    } else {
		PSYC.Packet request = PSYC.Packet("_request_authentication",
						  "nil", 
						  ([ "_location" : source ]));
		pending[s] 
		    = ([ id : send_tagged(id, request, 
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
	} else if (unl2uni[s] != id) {
	    m_delete(unl2uni, s);
	    return msg(p);
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
