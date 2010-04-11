// i am a tiny pie

#ifndef BIND
constant BIND = 0; // true for BIND!
#endif

#ifndef PORT
# define PORT 4044 // in your face!
#endif

class UCache {
    mapping(string:MMP.Uniform) c = ([]);

    MMP.Uniform get_uniform(string s) {
	if (!has_index(c, s)) {
	    c[s] = MMP.Uniform(s);
	}

	return c[s];
    }
}

MMP.Circuit out;

object server = UCache();

void msg(MMP.Packet p, object c) {
    if (p->vars["_id"] < 10) {
	send(p->vars["_id"] + 1);
    }
    werror("got: %O from %O\n", p, c);
}

void close(mixed ... args) {
    werror("%O was closed.\n", args);
}

void connected(int success, mixed ... args) {
    werror("connected (%O)\n", args);
    out = MMP.Circuit(args[0], msg, close, server);
}

void accept(mixed id) {
    Stdio.File f = id->accept();
    MMP.Circuit(f, msg, close, server);
}

void send(void|int id) {
    if (!out) error("do a connect first!\n");
    MMP.Packet p = MMP.Packet(Serialization.Atom("_string", "payload goes here"), ([ 
		    "_id" : id,
		    "_source" : MMP.Uniform("psyc://example.org/"), 
		    "_target" : MMP.Uniform("psyc://example.org/~user")
		    ]));
    out->send(p);
}

int main(int argc, array(string) argv) {
    object stdin, stdout, hilfe;
    //Stdio.Port p = Stdio.Port(PORT, accept, BIND);
    //p->set_id(p);


    stdin = Stdio.File();
    stdin->assign(Stdio.stdin);
    stdout = Stdio.File();
    stdout->assign(Stdio.stdout);

    hilfe = MMP.Utils.Hilfe(stdin, stdout);
    hilfe->variables->connect = connect;
    hilfe->variables->send = send;

    return -1;
}

void connect(string|void host, int|void port) {
    Stdio.File f = Stdio.File();
#ifdef BIND
    f->open_socket(UNDEFINED, BIND);
#endif
    f->async_connect(host || "127.0.0.1", port || 4044, connected, f, sprintf("%s:%d", host || "127.0.0.1", port || 4044));
}
