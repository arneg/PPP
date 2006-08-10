#include <debug.h>

inherit PSYC.Uni;
array(mixed) clients = ({ });
object user; // euqivalent to the _idea_ of "user.c" in psycmuve

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

PSYC.User get_user() {
    if (user) {
	return PSYC.User;
    }

    return user = PSYC.User(this);
}

int isNewbie() {
    return 0;
}

MMP.Uniform user_to_uniform(string l) {
    MMP.Uniform address;
    if (search(l, ":") == -1) {
	l = "psyc://" + server->def_localhost + "/~" + l;
    }
    address = server->get_uniform(l); 

    return address;
}

MMP.Uniform room_to_uniform(string l) {
    MMP.Uniform address;
    if (search(l, ":") == -1) {
	l = "psyc://" + server->def_localhost + "/@" + l;
    }
    address = server->get_uniform(l); 

    return address;
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
void create(string nick, MMP.Uniform uni, object server) {
    v = ([ "password" : "test" ]); // doch hier, weil wir dann mit storage den nick brauchen
    // soll die sich registern?
    write("user: %O\n", nick);
    ::create(uni, server);
}

void msg(MMP.Packet p) {
    P2(("User", "%O->msg(%O)\n", this, p))

    // this looks ugly
    if (::msg(p)) {
	P2(("User", "returning here, sir (%d)\n", __LINE__))
	return;// let Uni check for auth.
    }

    MMP.Uniform source = p["_source"];
    
    PSYC.Packet m = p->data;
    
    switch(m->mc) {
    case "_request_authentication":
	{
	    // for now this works fine
	    if (has_index(m->vars, "_location")) foreach (clients, object o) {
		if (m->vars["_location"] == o->location) {
		    send(p["_source"], m->reply("_notice_authentication", "yeeees!")); 
		    return;
		}
	    }
	    send(p["_source"], m->reply("_error_authentication", "noooo!"));
	    return;
	}
	return;
    case "_request_link":
	string pw = m["_password"];
	void temp(int bol, MMP.Packet packet) {
	    P2(("User", "temp here, sir (%d\n", __LINE__))
	    if (bol) {
		attach(PsycUser(packet["_source"], this));
		send(packet["_source"], m->reply("_notice_link", "You have been linked."));
	    } else if (pw) {
		send(packet["_source"], m->reply("_error_user_in_use", "This user is in use ,)."));
	    } else {
		send(packet["_source"], m->reply("_error_invalid_password", "Forgot your password?"));
		// maybe a newbie...
	    }
	};
	checkAuth("password", pw, temp, p); 
	return;
    case "_request_status":
    case "_notice_friend_present":
	if (sizeof(clients))
	    send(source, m->reply("_notice_friend_absent"));
	else 
	    send(source, m->reply("_status_friend_present"));
	break;
    case "_notice_friend_present_quiet":
	break;
    case "_request_unlink":
	// vielleicht sollte sich der User.Psyc selbst unlinken ,)
	return;
    case "_request_friendship":
    case "_request_exit":
    }

    clients->msg(p);
}

