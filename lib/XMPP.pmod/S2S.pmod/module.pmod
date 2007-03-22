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
	t16 += sprintf("%0x", t[i]);
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
    mapping(string:mapping) allowed_peers = ([ ]);
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
	    if (config["tls"]) {
		rawp("<proceed xmlns='urn:ietf:params:xml:ns:xmpp-tls'/>");
		starttls(0);
	    } else {
		// ...
	    }
	    return;
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
	    return;
	case "db:verify":
	    if (has_index(config["localhosts"], node->to)) {
		int valid;
		valid = dialback_key(config["secret"], node->id, node->from, 
				     node->to) == node->getData();
		rawp("<db:verify from='" + node->to + "' to='" + node->from 
		     + "' "+ "id='" + node->id + "' type='" 
		     + (valid ? "" : "in") 
		     + "valid'/>");
	    } else {
		// host-unknown error
	    }
	    return;
	}

	// at this point, packet MUST HAVE to and from 
	if (!(node->to && node->from)) {
	    werror("no to && from for %O\n", node->getName());
	    return;
	}
	// and from must be an allowed peer
	MMP.Uniform from = MMP.Uniform("xmpp:" + node->from);
	MMP.Uniform to = MMP.Uniform("xmpp:" + node->to);
	if (!(allowed_peers[to->host] && allowed_peers[to->host][from->host])) {
	    werror("not allowed: %s,%s not in %O\n", to->host, from->host,
		   allowed_peers);
	    return;
	}
	switch(node->getName()) {
#if 0
	case "message":
	    if (!to->user && to->resource == "Echo") {
		werror("send echo\n");
	    }
	    break;
#endif
	default:
	    werror("%O not handling %O\nXML: %O\n", 
		   this_object(), node->getName(), node->renderXML());
	    break;
	}
    }

    void verify_result(string we, string peer, int result) {
	if (!result) {
	} else {
	    if (!allowed_peers[we]) allowed_peers[we] = ([ ]);
	    allowed_peers[we][peer] = 1;
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
	    }
#endif
	    rawp("</stream:features");
	} 
	rawp(">");
    }
}

class Connector {
    inherit XMPP.XMPPSocket;
    int connecting;
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
	if (connecting) return;
	    connecting = 1;
	if (domain != "localhost")
	    MMP.Utils.DNS.async_srv(service, protocol, domain, srv_resolved);
	else
	    resolved("localhost", "127.0.0.1", 5269);
    }

    void srv_resolved(string query, MMP.Utils.DNS.SRVReply|int result) {
	// TODO: we should resolve both _xmpp-server and _jabber and then
	// 	prefer _xmpp-server if both are available
	if (objectp(result) && result->has_next()) {
	    mixed entry = result->next();
	    Protocols.DNS.async_host_to_ip(entry->target, resolved,
					   entry->port);
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
	werror("%O called with %O\n", this_object(), packet->data);
	switch(object_program(packet->data)) {
	case XMPP.XMLNode:
	    packet->data->to = packet["_target"]->userAtHost;
	    packet->data->from = packet["_source"]->userAtHost;
	    push(packet->data->renderXML());
	    break;
	default:
	    werror("unknown type\n");
	    werror("%O\n", object_program(packet->data));
	    break;
	}
    }

    void push(string msg) {
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
	::tls_logon(args);
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

    void do_dialback() {
	rawp("<db:result to='" + config["domain"] + "' "
	     "from='" + config["localdomain"] + "'>"
	     + dialback_key(config["secret"], streamattributes["id"],
			    config["domain"], config["localdomain"]) +
	     "</db:result>");
    }

    void handle() {
	switch(node->getName()) {
	case "stream:features":
	    foreach(node->getChildren(), XMPP.XMLNode x) {
		string name = x->getName();
#ifdef SSL_WORKS
		if (name == "starttls" && config["tls"]) {
		    rawp("<starttls xmlns='urn:ietf:params:xml:ns:xmpp-tls'/>");
		    return;
		}
#endif
	    }
	    werror("%O could now do dialback\n", this_object());
	    do_dialback();
	    break;
#ifdef SSL_WORKS
	case "proceed":
	    if (config["tls"])
		starttls(1);
	    else {
		// this is bad
	    }
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
		werror("dialback invalid?\n");
		// prepare to close the stream
	    }
	    break;
	default:
	    werror("%O not handling %O\n", this_object(), node->getName());
	    break;
	}
    }
    void open_stream(mapping attr) {
	::open_stream(attr);
	if (attr->version && attr->version == "1.0") { 
	    // wait for stream:features
	} else {
	    do_dialback();
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
	case "stream:features":
	    // we're not interested in doing tls, etc
	    do_dialback();
	    break;
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
    }
    void do_dialback() {
	rawp("<db:verify to='" + config->domain + "' from='" 
	     + config->localdomain + "' id='" + config->id + "'>" 
	     + config->key + "</db:verify>");
    }
}


class ClientManager { 
    mapping config;
    mapping remotes;
    void create(mapping _config) {
	config = _config;
	remotes = ([ ]);
    }
    void deliver_remote(MMP.Packet packet, MMP.Uniform target) {
	// TODO: we should catch packet not originating from a configured
	// 	localhost
	mixed handler;
	string domain = target->host;
	string localdomain = packet["_source"]->host;
	if (!has_index(remotes, localdomain))
	    remotes[localdomain] = ([ ]);
	if (!has_index(remotes[localdomain], domain))
	    remotes[localdomain][domain] = Client(config + 
					([ "domain" : domain,
					"localdomain" : localdomain]));
	handler = remotes[localdomain][domain];
	target->handler = handler;
	handler->msg(packet);
    }
}
