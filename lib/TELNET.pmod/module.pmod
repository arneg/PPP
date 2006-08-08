#define MOTD "hey hey, this is the magical telnet interface\r\n"
#define CMDCHAR '/'
#include <debug.h>

// one TELNET session. which attaches to a user and then.. sends psyc
class Session {

    object socket, server;
    User.Person user;
    string username;
    int attached, writeok;
    MMP.Uniform place;

 
    void create(object so, object se, function close) {
	socket = Protocols.TELNET.Readline(so, read, 0, close, ([]));
	server = se;
    }

    void write(string t) {
	socket->write(t);
    }

    void writeln(string t) {
	write(t+"\r\n");
    }
    
    void logon() {
	socket->set_prompt("Username: ");
    }

    void read(mixed id, string data) {

	P0(("PSYC.Session", "%O->read(%O, %O)\n", this, id, data))

	data = data[0..sizeof(data) - 2];

	if (!username) {
	    string unl;
	    unl = "psyc://" + server->def_localhost + "/~" + data;
	    username = data;
	    user = server->get_local(unl);

	    if (user->isNewbie()) {
		user->attach(this);

		attached = 1;
		//socket->readline->set_echo(0);
	    } else {
		socket->set_prompt("Password: ");
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
	    //socket->readline->set_echo(0);
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
		user->send(target, PSYC.Packet("_request_enter"));
		return;
	    }
	}
    }

    void msg(MMP.Packet p) {
	P0(("TELNET.Session", "%O->msg(%O)\n", this, p))

	PSYC.Packet m = p->data;
	
	switch(m->mc) {
	case "_echo_enter":
	    place = p["_source"];
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
