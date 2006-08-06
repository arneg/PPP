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

    int rawp(string what) {
	socket->write(what);
    }

    void handle() {
	if (node->getName() == "starttls") {
	    rawp("<proceed xmlns='urn:ietf:params:xml:ns:xmpp-tls'/>");
	    starttls(0);
	}
    }

    void open_stream(mapping attr) {
	::open_stream(attr);
	rawp("<?xml version='1.0' encoding='UTF-8' ?>"
	     "<stream:stream "
	     "xmlns='jabber:server' "
	     "xmlns:db='jabber:server:dialback' "
	     "xmlns:stream='http://etherx.jabber.org/streams' "
	     "xml:lang='en' id='MAKEMERANDOM' ");
	if (attr->to) {
	    rawp("from='" + attr->to + "' ");
	} else {
	    rawp("from='" + _config["defaulthost"] + "' ");
	}

	if (attr->version == "1.0") {
	    rawp("version='1.0'>");
	    rawp("<stream:features>");
	    if (!Program.inherits(object_program(socket), SSL.sslfile)) {
		rawp("<starttls xmlns='urn:ietf:params:xml:ns:xmpp-tls'/>");
	    } else {
		werror("already done starttls\n");
	    }
	    rawp("</stream:features>");
	}
    }
}


Protocols.DNS.async_client _resolver = Protocols.DNS.async_client();

void async_srv(string service, string protocol, string name,
               function cb, mixed ... cba) {
    _resolver->do_query("_" + service +"._"+ protocol + "." + name,
			Protocols.DNS.C_IN,
			Protocols.DNS.T_SRV, sort_srv, cb, cba);
}

void sort_srv(string query, mapping result, mixed cb, mixed cba) {
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
        cb(query, res, cba);
    } else {
        cb(-1, cba);
        werror("dns client: no result\n");
    }
}


class Client {
    inherit XMPP.XMPPSocket;
    void create(mapping(string:mixed) config) {
	::create(config);
	async_srv("xmpp-server", "tcp", config["domain"], srv_resolved);
    }
    void srv_resolved(string query, array result, mixed args) {
	// TODO: we should resolve both _xmpp-server and _jabber and then
	// 	prefer _xmpp-server if both are available
	if (sizeof(result)) {
	    mixed entry = result[0];
	    Protocols.DNS.async_host_to_ip(entry[3], resolved, entry[2]);
	} else {
	    Protocols.DNS.async_host_to_ip(_config["domain"], resolved, 5269);
	}
    }

    void resolved(string host, string ip, int port) {
	socket = Stdio.File();
	socket->async_connect(ip, port, logon);
    }

    void logon(int success) {
	werror("logon(%O)\n", success);
	if (success) {
	    socket->set_nonblocking(read, write, close);
	    rawp("<stream:stream "
		 "xmlns:stream='http://etherx.jabber.org/streams' "
		 "xmlns='jabber:server' xmlns:db='jabber:server:dialback' "
		 "to='" + _config["domain"] + "' "
		 "from='" + _config["localdomain"] + "' "
		 "xml:lang='en' "
		 "version='1.0'>");
	}
    }

    void tls_logon(mixed ... args) {
	rawp("<stream:stream "
	     "xmlns:stream='http://etherx.jabber.org/streams' "
	     "xmlns='jabber:server' xmlns:db='jabber:server:dialback' "
	     "to='" + _config["domain"] + "' "
	     "from='" + _config["localdomain"] + "' "
	     "xml:lang='en' "
	     "version='1.0'>");
    }

    int rawp(string what) {
	socket->write(what);
    }
    void handle() {
	switch(node->getName()) {
	case "stream:features":
	    foreach(node->getChildren(), XMPP.XMLNode x) {
		string name = x->getName();
		if (name == "starttls") {
		    rawp("<starttls xmlns='urn:ietf:params:xml:ns:xmpp-tls'/>");
		    return;
		}
	    }
	    werror("%O could now do dialback\n", this_object());
	    break;
	case "proceed":
	    starttls(1);
	    break;
	case "stream:stream": 
	    werror("should have reset stream\n");
	    break;
	}

    }

}
