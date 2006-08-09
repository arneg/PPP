#define MOTD "hey hey, this is the magical telnet interface\r\n"
#define CMDCHAR '/'
#define LINEUP(n)	("\e[" + (string)(n) + "A")
#define LINEDOWN(n)	("\e[" + (string)(n) + "B")
#define KILLLINE "\e[K"
#include <debug.h>

// one TELNET session. which attaches to a user and then.. sends psyc
class Session {

    object socket, server;
    User.Person user;
    string username;
    int attached, writeok;
    multiset(MMP.Uniform) places = (< >);
    MMP.Uniform place;

    void clear_line() {
	socket->write_raw(KILLLINE);
    }
 
    void create(object so, object se, function close) {
	socket = Protocols.TELNET.Readline(so, read, 0, close, ([]));
	server = se;
    }
    
    void write(string t) {
	socket->write(t);
    }

    void writeln(string t) {
	string old_prompt = socket->readline->set_prompt("");
	int old_pos = socket->readline->getcursorpos();
	array(string) workon = t / "\n";

	if (sizeof(workon) > 1) {
	    for (int i = 0; i < sizeof(workon) - 2; i++) {
		if (workon[i][-1] != '\r') {
		    workon[i] += "\r";
		}
	    }

	    t = workon * "\n";
	}

	socket->write_raw(LINEUP(1));
	clear_line();
	write(t+"\r\n");
	socket->readline->set_prompt(old_prompt);
	socket->readline->redisplay(0);
	socket->readline->setcursorpos(old_pos);
    }
    
    void logon() {
	socket->set_prompt("Username: ");
    }

    void read(mixed id, string data) {

	socket->readline->setcursorpos(0);
	P0(("PSYC.Session", "%O->read(%O, %O)\n", this, id, data))

	if (sizeof(data) < 2) {
	    //
	    return;
	}

	data = data[0..sizeof(data) - 2];


	if (!username) {
	    string unl;
	    unl = "psyc://" + server->def_localhost + "/~" + data;
	    username = data;
	    user = server->get_local(unl);

	    if (user->isNewbie()) {
		user->attach(this);

		attached = 1;
	    } else {
		socket->readline->set_echo(0);
		socket->readline->set_prompt("Password: ");
	    }
	    return;
	}

	if (!attached) {
	    user->checkAuth("password", data, _auth);
	    return;
	}


	if (data[0] == CMDCHAR) {
	    cmd(data[1..] / " "); 
	    return;
	}

	if (place) {
	    user->send(place, PSYC.Packet("_message_public", data)); 
	    return;
	}

	writeln("join a room, you kinky bastard!");
    }

    void _auth(int bol) {
	if (bol) {
	    user->attach(this);

	    attached = 1;
	    socket->readline->set_prompt("");
	    socket->readline->set_echo(1);
	} else {
	    write("wrong password...\r\n");
	    socket->close();
	}
    }

    void cmd(array(string) arg) {
	switch(arg[0]) {
	case "quit":
	    user->detach(this); 
	    writeln("goodbye");
	    socket->close();
	    return;
	case "join":
	    {
		MMP.Uniform target = user->room_to_uniform(arg[1]);
		user->send(target, PSYC.Packet("_request_enter", 0, 
			       ([ "_nick" : user->uni->resource[1..] ])));
		return;
	    }
	    return;
	case "change":
	    {
		MMP.Uniform target = user->room_to_uniform(arg[1]);

		if (has_index(places, target)) {
		    place = target;
		    socket->readline->set_prompt(target->unl + "> ");
		}
	    }
	}
    }

    void msg(MMP.Packet p) {
	P0(("TELNET.Session", "%O->msg(%O)\n", this, p))

	PSYC.Packet m = p->data;
	
	switch(m->mc) {
#ifdef STILLE_DULDUNG
	case "_notice_place_leave":
#endif
	case "_notice_leave":

	if (p->source == user->uni) {
		MMP.Uniform tmp = p["_source"];

		if (place == tmp) {
		    place = UNDEFINED;
		    socket->readline->set_prompt("> ");
		}

		places[tmp] = 0;
	    }

	    break;
#ifdef STILLE_DULDUNG
	case "_echo_place_enter":
#endif
	case "_echo_enter":
	    place = p["_source"];
	    places[place] = 1;
	    socket->readline->set_prompt(place->unl + "> ");
	    break;
	}

	writeln(PSYC.psyctext(p));
    }
}

// handles different TELNET sessions for local users..
class Server {

    mapping(string:TELNET.Session) sessions = ([]);
    object psyc_server;

    void close(TELNET.Session tn) {
	P0(("TELNET.Server", "closing %s.\n", tn->socket->query_address()))
	m_delete(sessions, tn->socket->query_address());
    }

    void accept(Stdio.Port lsocket) {
        string peerhost;
        Stdio.File socket;
        socket = lsocket->accept();
        peerhost = socket->query_address();

	P0(("TELNET.Server", "accepted connection from %s in %O\n", peerhost, sessions))

        sessions[peerhost] = TELNET.Session(socket, psyc_server, close);
	sessions[peerhost]->write(MOTD);
	sessions[peerhost]->logon();
	P0(("TELNET.Server", "blub\n"))
    }

    void create(mapping config) {
	
	if (has_index(config, "psyc_server")) {
	    psyc_server = config["psyc_server"];
	}

	if (has_index(config, "ports")) {
            // more error-checking would be a good idea.
            int|string port;
            string ip;
            Stdio.Port p;
            foreach (config["ports"], port) {
                if (intp(port)) {
                    p = Stdio.Port(port, accept);
                } else { // is a string
                    [ip, port] = (port / ":");
                    p = Stdio.Port(port, accept, ip);
                }
                p->set_id(p);
            }
        } else throw("help!");
    }

    
    
}
