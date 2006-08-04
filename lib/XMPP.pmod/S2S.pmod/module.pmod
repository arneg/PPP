// vim:syntax=lpc
// 
#include <debug.h>

class Server {
    inherit XMPP.XMPPSocket;

    mapping(string:mixed) localhosts;
    string bind_to;
    function create_local, create_remote;

    void create(mapping(string:mixed) config) {
	// TODO: expecting ip:port ... is maybe a bit too much
	// looks terribly ugly..
	if (has_index(config, "localhosts")) { 
	    localhosts = config["localhosts"];
	} else {
	    localhosts = ([ ]);
	}
	localhosts += ([ 
			"localhost" : 1,
			"127.0.0.1" : 1,
		      ]);

	if (has_index(config, "create_local") 
	    && functionp(create_local = config["create_local"])) {
	} else {
	    throw("urks");
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
		    localhosts[ip] = 1;
		    bind_to = ip;
		}
		p->set_id(p);
	    }
	} else throw("help!");
	::create(config);
    }

    void accept(Stdio.Port lsocket) {
	string peerhost;

	werror("accepted\n");
	Stdio.File socket;
	socket = lsocket->accept();
	peerhost = socket->query_address();
	socket->set_nonblocking(read, write, close);
    }

    int read(mixed id, string data) {
	xmlParser->feed(data);
    }

    int write(void|mixed id) {
	werror("write called\n");
    }

    int close(mixed id) {
	werror("closed\n");
    }

}

class Client {
    void create(mapping(string:mixed) config) {
	//so->async_connect(ip, port, connect, so, q, target, id);
	//Protocols.DNS.async_host_to_ip(host, cb, port, packet);
    }
}
