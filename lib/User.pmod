//vim:syntax=lpc
/*
 * this is supposed to be a general "minimal" object for a user without
 * anyone being linked to it. 
 *
 * vielleicht sollten wir eine person noch unterteilen in einen wirklich
 * existierenden user und einen newbie. der muss sich naemlich wirklich nur
 * linken lassen. auch das halte ich in unterschiedlichen klassen
 * besser gelöst als mit einem is_newbie()
 */

class Person {
    inherit Uni;
    array(mixed) clients = ({ });
    // wie waren diese unterschiedlichen level? fippo hatte doch das alles
    // sich genau überlegt.
    // friends landet dann ja wohl im v..
    mixed v;

    // i don't know whether attach should check auth or if we want to live
    // in an enviroment where the attacher has to check auth (and we trust
    // everyone)
    void attach(object o) {
	clients += ({ o });
    }

    void detach(object o) {
	clients -= ({ o });
    }

    void checkAuth(string type, mixed creds, function cb, 
		   mixed ... extra) {
	if (type != "password") {
	    throw(({ "invalid auth method provided\n", 0 }));
	}

	if (!stringp(creds)) {
	    throw(({ "invalid creds provided\n",
		  backtrace() }));
	}

	if (has_index(v, "password")) {
	    cb(creds == v["password"], @extra);
	} else {
	    cb(!sizeof(clients), @extra);
	}
    }

    // vielleicht ist das nicht gut
    void create(string nick, string uni, object server) {
	v = ([ "password" : "test" ]); // doch hier, weil wir dann mit storage den nick brauchen
	// soll die sich registern?
	write("user: %O\n", nick);
	::create(uni, server);
    }

    void msg(MMP.Packet p) {

	// this looks ugly
	if (!::msg(p))
	    return;// let Uni check for auth.

	string source = p["_source"];
	
	PSYC.Packet m = p->data;
	
	switch(m->mc) {
	case "_request_authentication":
	    {
		// for now this works fine
		if (has_index(m->vars, "_location")) foreach (clients, object o) {
		    if (m->vars["_location"] == o->location) {
			send(p["_source"], PSYC.reply(m, "_notice_authentication", "yeeees!")); 
			return;
		    }
		}
		send(p["_source"], PSYC.reply(m, "_error_authentication", "noooo!")); 
		return;
	    }
	    return;
	case "_request_link":
	    string pw = m["_password"];
	    void temp(int bol, MMP.Packet packet) {
		if (bol) {
		    attach(PsycUser(packet["_source"], this));
		    send(packet["_source"], PSYC.reply(p->data, "_notice_link", "You have been linked."));
		} else if (pw) {
		    send(packet["_source"], PSYC.reply(p->data, "_error_user_in_use", "This user is in use ,)."));
		} else {
		    send(packet["_source"], PSYC.reply(p->data, "_error_invalid_password", "Forgot your password?"));
		    // maybe a newbie...
		}
	    };
	    checkAuth("password", pw, temp, p); 
	    return;
	case "_request_status":
	case "_notice_friend_present":
	    if (sizeof(clients))
		sendmsg(source, "_notice_friend_absent");
	    else 
		sendmsg(source, "_status_friend_present");
	    break;
	case "_notice_friend_present_quiet":
	    break;
	case "_request_unlink":
	    // vielleicht sollte sich der User.Psyc selbst unlinken ,)
	    return;
	case "_request_friendship":
	case "_request_exit":
	}

	clients->msg(m);
    }

}

class PsycUser {

    // could be the connection-object.
    string location;
    object person;

    void create(string loc, object p) {
	location = loc;
	person = p;
    }

    // we need an itsme check.. somewhere
    void msg(MMP.Packet p) { 

	PSYC.Packet m = p->data;

	switch (m->mc) {
	case "_request_store":
	    {
		string key;
		foreach (indices(m->vars), key) {
		    if (key[0] == '_' && MMP.is_mmpvar(key))
			person->v[key] = m->vars[key];
		}
	    }
	    break;
	case "_request_retrieve":
	    {
		string key;
		mapping t = copy_value((mapping)(person->v));

		// hmm. maybe we should store them in different mappings internally
		// and .. hmm. we can do that for every storage type, can't we?
		// we wont use plain mappings.. will we? ,)
		//
		//TODO: we should decide whether the library may corrupt vars or not
		//.. maybe its worth allowing that.. maybe not.
		//
		// maybe pike even optimizes calls for copy_vars like:
		// return sendmsg(bla, copy_value(vars));
		// if the reference count of vars is 1.
		foreach (indices(t), key) {
		    if (key[0] != '_')
			m_delete(t, key);
		}
		
		person->sendmsg(p["_source"], "_status_storage", 0, t);
	    }
	    break;
	case "_request_execute":
	    break;
	}
	
	person->send(location, m);
    }
    
}
