// vim:syntax=lpc
#define MOTD "hey hey, this is the magical telnet interface\r\n"
#define CMDCHAR '/'
#define LINEUP(n)	("\e[" + (string)(n) + "A")
#define LINEDOWN(n)	("\e[" + (string)(n) + "B")
#define KILLLINE "\e[K"
#define KILLDOWN "\e[J"
#include <debug.h>

// one TELNET session. which attaches to a user and then.. sends psyc
class Session {
    inherit PSYC.CommandSingleplexer;

    object textdb;
    object debug;
    object socket, server;
    MMP.Uniform user;
    PSYC.Client client;
    string username;
    int attached, writeok;
    function set_password;
    function SKINNER;
    function textdbfac;

    class GroovyTelnetPromptChangeHandler {
	inherit PSYC.Handler.Base;

	constant _ = ([
	    "display" : ([
		"_notice_link" : 0,
		"_notice_context_enter": 0,
	    ]),
	]);

	int display_notice_link(MMP.Packet p, mapping _v, mapping _m) {
	    socket->readline->set_prompt("> ");
	    socket->readline->redisplay();
	    socket->readline->set_echo(1);
	    input_to(read);

	    return PSYC.Handler.GOON;
	}

	int display_notice_context_enter(MMP.Packet p, mapping _v, mapping _m) {
	    MMP.Uniform place = p["_group"];

	    if (p["_supplicant"] == client->link_to) {
		socket->readline->set_prompt((string)place->unl + "> ");
	    }

	    return PSYC.Handler.GOON;
	}
    }

    class UngroovyTelnetDisplayHandler {
	inherit PSYC.Handler.Base;

	object textdb;

	constant _ = ([
	    "display" : ([
		"" : 0,
	    ]),
	]);

	void create(mapping params) {
	    ::create(params);
	    textdb = params["textdb"];
	}

	int display(MMP.Packet p, mapping _v, mapping _m) {
	    P0(("TELNET.UngroovyTelnetDisplayHandler", "display(%O)\n", p))
	    writeln((objectp(p->data) ? p->data->mc : "an mc-less packet") + "\t" + PSYC.psyctext(p, textdb));

	    return PSYC.Handler.GOON;
	}
    }

    void input_to(function|void _input_) {
	SKINNER = _input_;
    }

    int superintendent_read(mixed id, string data) {
	fix_prompt(data);

	data = data[0..sizeof(data)-2];

	if (SKINNER && sizeof(data)) {
	    return SKINNER(id, data);
	}

	return 0;
    }

    void clear_line() {
	socket->write_raw(KILLLINE);
    }
 
    void create(object so, object se, function close, function textdbfac_, object d) {
	input_to(read_username);
	debug = d;

	socket = Protocols.TELNET.Readline(so, superintendent_read, 0,
					   close, ([]));
	server = se;
	textdb = (textdbfac = textdbfac_)("plain", "en");
    }
    
    void write(string t) {
	socket->write(t);
    }

    void writeln(string t) {
	string old_prompt = socket->readline->set_prompt("");
	int old_pos = socket->readline->getcursorpos();
	array(string) workon = t / "\n";

	socket->readline->setcursorpos(0);
	socket->write_raw(KILLDOWN);

	if (sizeof(workon) > 1) {
	    for (int i = 0; i < sizeof(workon) - 2; i++) {
		if (workon[i][-1] != '\r') {
		    workon[i] += "\r";
		}
	    }

	    t = workon * "\n";
	}

	//clear_line();
	write(t+"\r\n");
	socket->readline->set_prompt(old_prompt);
	socket->readline->setcursorpos(old_pos);
	socket->readline->redisplay(0);
    }
    
    void logon() {
	socket->set_prompt("Username: ");
    }

    void fix_prompt(string data) {
	int lines;

	socket->write_raw(LINEUP(lines = (
				  sizeof(socket->readline->get_prompt())
				  + sizeof(data))
				  / socket->readline->get_output_controller()->get_number_of_columns()
				 + 1));
	if (sizeof(data) < 2) {
	    clear_line();
	    socket->write_raw(LINEDOWN(lines));
	}

	socket->readline->redisplay();
	//socket->readline->setcursorpos(0);
    }

    void read_username(mixed id, string data) {

	username = data;

	if (search(data, ":") == -1) {
	    user = server->get_uniform("psyc://" + server->def_localhost + "/~" + data);
	} else {
	    user = server->get_uniform(data);
	}

	MMP.Uniform unl = server->random_uniform("telnet");
	mapping params = ([
	    "person" : user,
	    "uniform" : unl,
	    "server" : server,
	    "textdb" : textdb,
	    "debug" : debug,
	]);
	client = PSYC.Client(params + ([ "query_password" : query_password, "error" : query_password ]));

	params += ([
	    "uniform" : client->uni,
	    "sendmmp" : client->client_sendmmp,
	    "parent" : client,
		   ]);

	unl->handler = client;
	client->attach(this);
	client->add_handlers(
			     GroovyTelnetPromptChangeHandler(params),
			     UngroovyTelnetDisplayHandler(params),
			     );

	add_commands(PSYC.Commands.Tell(params));
	//add_commands(PSYC.Commands.Subscribe(this));
	add_commands(PSYC.Commands.Enter(params));
	add_commands(PSYC.Commands.Set(params));
	add_commands(PSYC.Commands.Channel(params));

	input_to();
    }

    void query_password(MMP.Packet p, function cb) {
	socket->readline->set_echo(0);
	socket->readline->set_prompt("Password: ");
	input_to(read_password);
	set_password = cb;
    }

    void read_password(mixed id, string data) {
	fix_prompt(data);
	P0(("PSYC.Session", "%O->read_password(%O, %O)\n", this, id, data))

	input_to();
	call_out(set_password, 0, data);
    }

    void read(mixed id, string data) {
	P0(("PSYC.Session", "%O->read(%O, %O)\n", this, id, data))

	if (data[0] == CMDCHAR) {
	    cmd(data[1..]); 
	    return;
	}

	writeln("join a room, you kinky bastard!");
    }

}

// handles different TELNET sessions for local users..
class Server {

    mapping(string:TELNET.Session) sessions = ([]);
    object psyc_server, debug;
    function textdb;

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

        sessions[peerhost] = TELNET.Session(socket, psyc_server, close, textdb, debug);
	sessions[peerhost]->write(MOTD);
	sessions[peerhost]->logon();
	P0(("TELNET.Server", "blub\n"))
    }

    void create(mapping config) {
	
	if (has_index(config, "psyc_server")) {
	    psyc_server = config["psyc_server"];
	}

	if (has_index(config, "textdb")) {
	    textdb = config["textdb"];
	} else throw("no");

	// bad dependency here
	debug = config["debug"] || MMP.Utils.DebugManager();

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
