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
    int rawp(string what) {
	socket->write(what);
    }

    int close(mixed id) {
	werror("closed\n");
    }

    void handle() {
	if (node->getName() == "starttls") {
	    rawp("<proceed xmlns='urn:ietf:params:xml:ns:xmpp-tls'/>");
	    starttls();
	}
	::handle();
    }

    void starttls() {
	SSL.context ctx = SSL.context();
	ctx->rsa = Standards.PKCS.RSA.parse_private_key(_config["key"]["localhost"]);
	ctx->random = Crypto.Random.random_string;
	ctx->certificates = ({ _config["certificates"]["localhost"]});
	sslsocket = SSL.sslfile(socket, ctx);
	sslsocket->set_read_callback(read);
	sslsocket->set_write_callback(write);
	sslsocket->set_close_callback(close);
    }
    void open_stream(mapping attr) {
	if (attr->version == "1.0") {
	    werror("1.0\n");
	    rawp("<stream:features>");
	    rawp("<starttls xmlns='urn:ietf:params:xml:ns:xmpp-tls'/>");
	    rawp("</stream:features>");
	}
	::open_stream(attr);
    }
}

class Client {
    void create(mapping(string:mixed) config) {
    }
	//so->async_connect(ip, port, connect, so, q, target, id);
	//Protocols.DNS.async_host_to_ip(host, cb, port, packet);
// async srv hint: 
#if 0
// hints: wie loest man async srv auf
void callback(string query, mapping result, mixed cb, mixed ... cba) {
    werror("callback? %O(%O)\n", cb, cba);
    array res=({});

    if (result) {

        foreach(result->an, mapping x)
        {
           res += ({({x->priority, x->weight, x->port, x->target})});
        }

        // now we sort the array by priority as a convenience
        array y=({});
        foreach(res, array t)
          y+=({t[0]});
        sort(y, res);
        cb(res, cba);
    } else {
        cb(-1, cba);
        werror("dns client: no result\n");
    }
}

void async_srv(string service, string protocol, string name,
               function cb, mixed ... cba) {
    Protocols.DNS.async_client client = Protocols.DNS.async_client();
    client->do_query("_" + service +"._"+ protocol + "." + name,
                     Protocols.DNS.C_IN,
                     Protocols.DNS.T_SRV, callback, cb, cba);

}
#endif
}
