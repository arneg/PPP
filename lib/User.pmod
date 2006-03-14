/*
 * this is supposed to be a general "minimal" object for a user without
 * anyone being linked to it. 
 */

class Person {
    array(mixed) clients = ({ });
    // wie waren diese unterschiedlichen level? fippo hatte doch das alles
    // sich genau überlegt.
    // friends landet dann ja wohl im v..
    mapping(string:int) friends = ([ ]);
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

    void checkAuth(string type, mixed creds, function(int:mixed) cb, 
		   array(mixed) extra) {
	if (type != "password") {
	    throw(({ "invalid auth method provided\n",
		   backtrace() }));
	}

	if (!stringp(creds)) {
	    throw(({ "invalid creds provided\n",
		  backtrace() }));
	}

	if (has_index(v, "password")) {
	    cb(creds == v["password"]);
	} else {
	    cb(!sizeof(clients));
	}
    }

    // vielleicht ist das nicht gut
    void create(string nick) {
	v = ([ ]); // doch hier, weil wir dann mit storage den nick brauchen
	// soll die sich registern?
	register_uniform();
    }

    void msg(psyc_p m) {
	string source = m["_source"];
	
	switch(m->mc) {

	case "_request_link":
	    string pw = m["_password"];
	    void temp(int bol, Person p, string location) {
		if (bol) {
		    p->attach(User.Psyc(location));
		    sendmsg(location, "_notice_link");
		} else 
		    sendmsg(location, "_error_invalid_password");
		    // maybe a newbie...
	    }
	    checkAuth("password", pw, temp); 
	    return;

	case "_request_unlink":
	    // vielleicht sollte sich der User.Psyc selbst unlinken ,)
	    return;
	case "_request_friendship":
	case "_request_exit":
	}

	clients->msg(m);
    }

}

class Psyc {

    // could be the connection-object.
    string location;

    void create(string loc) {
	location = loc;
    }

    void msg(psyc_p m) { 

	switch (m->mc) {
	case "_request_store":
	case "_request_execute":
	
	}
	
	sendmsg(location, m);
    }
    
}


