// vim:syntax=lpc
// 
#include <debug.h>

#define RANDHEXSTRING sprintf("%x", random(65536))

string dialback_key(string secret, string streamid, 
		      string receiving, string originating) {
    werror("dialback_key(%O, %O, %O, %O)\n",
	   secret, streamid,receiving, originating);
    mixed h = Crypto.HMAC(Crypto.SHA256)(secret);
    string t = h(streamid + receiving + originating);
    string t16 = "";
    for (int i = 0; i < sizeof(t); i++) {
	t16 += sprintf("%x", t[i]);
    }
    return t16;
}

class ServerManager {
    mapping config;
    mapping connections;
    void create(mapping(string:mixed) _config) {
	connections = ([ ]);
	config = _config;

	if (has_index(_config, "ports")) {
	    // more error-checking would be a good idea.
	    int|string port;
	    string ip;
	    Stdio.Port p;
	    foreach (_config["ports"], port) {
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

    void accept(Stdio.Port _socket) {
	string peerhost;
	Server t;

	t = Server(config);
	peerhost = t->accept(_socket);
	connections[peerhost] = t;
    }
}

class Server {
    inherit XMPP.XMPPSocket;

    mapping(string:mixed) localhosts;
    mapping(string:int) allowed_peers = ([ ]);
    string streamid;

    void msg(MMP.Packet packet, void|object connection) {
    }

    int rawp(string what) {
	socket->write(what);
    }

    void handle() {
	switch(node->getName()) {
#ifdef SSL_WORKS
	case "starttls":
	    rawp("<proceed xmlns='urn:ietf:params:xml:ns:xmpp-tls'/>");
	    starttls(0);
	    break;
#endif
	case "db:result":
	    /* clone a new s2s active connection that will ONLY do dialback */
	    if (has_index(config["localhosts"], node->to)) {
		DialbackClient c = DialbackClient(([
					"domain" : node->from,
					"localdomain" : node->to, 
					"id" : streamid,
					"key" : node->getData(),
					"callback" : this_object()
				    ]));
	    } else {
		// host-unknown error
	    }
	    break;
	case "db:verify":
	    {
	    int valid;
	    valid = dialback_key(config["secret"], node->id, node->from, 
				 node->to) == node->getData();
	    rawp("<db:verify from='" + node->to + "' to='" + node->from + "' "
		 + "id='" + node->id + "' type='" + (valid ? "" : "in") 
		 + "valid'/>");
	    }
	    break;
	default:
	    werror("%O not handling %O\nXML: %O\n", 
		   this_object(), node->getName(), node->renderXML());
	    break;
	}
    }

    void verify_result(string we, string peer, int result) {
	if (!result) {
	} else {
	    allowed_peers[({ we, peer })] = 1;
	}
	rawp("<db:result from='" + we + "' to='" + peer + "' type='"
	     + (result ? "" : "in") + "valid'/>");
    }

    void open_stream(mapping attr) {
	::open_stream(attr);
	streamid = RANDHEXSTRING;
	rawp("<?xml version='1.0' encoding='UTF-8' ?>"
	     "<stream:stream "
	     "xmlns='jabber:server' "
	     "xmlns:db='jabber:server:dialback' "
	     "xmlns:stream='http://etherx.jabber.org/streams' "
	     "xml:lang='en' id='" + streamid + "' ");
	if (attr->to) {
	    rawp("from='" + attr->to + "' ");
	} else {
	    rawp("from='" + config["default_localhost"] + "' ");
	}

	if (attr->version == "1.0") {
	    rawp("version='1.0'>");
	    rawp("<stream:features>");
#ifdef SSL_WORKS
	    if (!Program.inherits(object_program(socket), SSL.sslfile)) {
		rawp("<starttls xmlns='urn:ietf:params:xml:ns:xmpp-tls'/>");
	    } else {
		werror("already done starttls\n");
	    }
#endif
	    rawp("</stream:features");
	} 
	rawp(">");
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

class Connector {
    inherit XMPP.XMPPSocket;
    void resolved(string host, string ip, int port) {
	werror("resolved %O to %O\n", host, ip);
	socket = Stdio.File();
	socket->async_connect(ip, port, logon);
    }
    void logon(int success) {
	werror("%O logon(%O)\n", this_object(), success);
	if (success) {
	    socket->set_nonblocking(read, write, close);
	}
    }
}

class SRVConnector {
    inherit Connector;

    string service, protocol, domain;
    void create(mapping _config, 
		string _domain, string _service, string _protocol) {
	::create(_config);
	domain = _domain;
	service = _service;
	protocol = _protocol;
    }
    void connect() {
	if (domain != "localhost")
	    async_srv(service, protocol, domain, srv_resolved);
	else
	    resolved("localhost", "127.0.0.1", 5269);
    }

    void srv_resolved(string query, array result, mixed args) {
	// TODO: we should resolve both _xmpp-server and _jabber and then
	// 	prefer _xmpp-server if both are available
	if (sizeof(result)) {
	    mixed entry = result[0];
	    Protocols.DNS.async_host_to_ip(entry[3], resolved, entry[2]);
	} else {
	    Protocols.DNS.async_host_to_ip(config["domain"], resolved, 5269);
	}
    }
}


class Client {
    inherit SRVConnector;

    MMP.Utils.Queue outQ;
    int dialback_started;
    int ready;

    void create(mapping(string:mixed) _config) {
	outQ = MMP.Utils.Queue();
	SRVConnector::create(_config, _config["domain"], "xmpp-server", "tcp");
    }

    string _sprintf(int type) {
	if (type == 's' || type == 'O') {
	    return sprintf("XMPP.S2S.Client(%s -> %s)", 
			   config["localdomain"], config["domain"]);
	}
	return "XMPP.S2S.Client()";
    }

    void msg(MMP.Packet packet, void|object connection) {
    }

    // dirty hack
    void xmlmsg(string msg) {
	if (ready) {
	    rawp(msg);
	} else {
	    outQ->push(msg);
	    connect();
	}

    }

    void logon(int success) {
	::logon(success);
	if (success) {
	    rawp("<stream:stream "
		 "xmlns:stream='http://etherx.jabber.org/streams' "
		 "xmlns='jabber:server' xmlns:db='jabber:server:dialback' "
		 "to='" + config["domain"] + "' "
		 "from='" + config["localdomain"] + "' "
		 "xml:lang='" + (config["language"] || "en") + "' "
		 "version='1.0'>");
	}
    }
#ifdef SSL_WORKS
    void tls_logon(mixed ... args) {
	rawp("<stream:stream "
	     "xmlns:stream='http://etherx.jabber.org/streams' "
	     "xmlns='jabber:server' xmlns:db='jabber:server:dialback' "
	     "to='" + config["domain"] + "' "
	     "from='" + config["localdomain"] + "' "
	     "xml:lang='en' "
	     "version='1.0'>");
    }
#endif

    int rawp(string what) {
//	werror("%O >> %O\n", this_object(), what);
	socket->write(what);
    }

    void handle() {
	switch(node->getName()) {
	case "stream:features":
	    foreach(node->getChildren(), XMPP.XMLNode x) {
		string name = x->getName();
#ifdef SSL_WORKS
		if (name == "starttls") {
		    rawp("<starttls xmlns='urn:ietf:params:xml:ns:xmpp-tls'/>");
		    return;
		}
#endif
	    }
	    werror("%O could now do dialback\n", this_object());
	    rawp("<db:result to='" + config["domain"] + "' "
		 "from='" + config["localdomain"] + "'>"
		 + dialback_key(config["secret"], streamattributes["id"],
				config["domain"], config["localdomain"]) +
		 "</db:result>");
	    break;
#ifdef SSL_WORKS
	case "proceed":
	    starttls(1);
	    break;
#endif
	case "db:result":
	    if (node->type == "valid") {
		mixed what;
		werror("%O dialback success\n", this_object());
		ready = 1;
		// go ahead and send for originating domain
		while((what = outQ->shift())) {
		    rawp(what);
		}
	    } else {
		// prepare to close the stream
	    }
	    break;
	default:
	    werror("%O not handling %O\n", this_object(), node->getName());
	    break;
	}
    }
}

class DialbackClient {
    inherit Client;

    void create(mapping(string:mixed) _config) {
	::create(_config);
	connect();
    }
    string _sprintf(int type) {
	if (type == 's' || type == 'O') {
	    return sprintf("XMPP.S2S.DialbackClient(%s -> %s)", 
			   config["localdomain"], config["domain"]);
	}
	return "XMPP.S2S.DialbackClient()";
    }
    void handle() {
	switch(node->getName()) {
	case "db:verify":
	    if (node->id) {
		if (node->id == config->id) 
		    config->callback->verify_result(node->to, node->from, 
					    (node->type == "valid"));
		else {
		    // invalid-id error?
		}
	    }
	    break;
	default:
	    werror("%O (not) handling %O\n", this_object(), node->getName());
	}
    }

    void open_stream(mapping attr) {
	::open_stream(attr);
	// TODO: we should politely wait for stream:features before
	// sending this if version >= 1.0
	rawp("<db:verify to='" + config->domain + "' from='" 
	     + config->localdomain + "' id='" + config->id + "'>" 
	     + config->key + "</db:verify>");
    }
}


class ClientManager { 
    mapping config;
    void create(mapping _config) {
	config = _config;
    }
    Client createRemote(string domain) {
	return Client(config + ([ "domain" : domain ]));
    }
}
