// vim:syntax=lpc
// put that somewhere else.. maybe
//
#define THROW(s)	throw(({ (s), backtrace() }))
#include <debug.h>

class Dummy(mixed...params) { }

class uniform {
    string scheme, transport, host, user, resource, slashes, query, body,
	   userAtHost, pass, hostPort, circuit, root, unl;
    int port;

    mixed cast(string type) {
	if (type == "string") return unl;
    }

    string _sprintf(int type) {
	if (type == 's') {
	    return sprintf("PSYC.uniform(%s)", unl);
	} else if (type = 'O') {
	    return sprintf("PSYC.uniform(%O)", 
			   aggregate_mapping(@Array.splice(indices(this), values(this))));
	}

	return UNDEFINED;
    }
}

uniform parse_uniform(string s) {
    string t;
    uniform u = uniform();

    u->unl = s;
    t = s;
    if (!sscanf(t, "%s:%s", u->scheme, t)) THROW("this is not uniforminess");
    u->slashes = "";
    switch(u->scheme) {
    case "sip":
	    sscanf(t, "%s;%s", t, u->query);
	    break;
    case "xmpp":
    case "mailto":
	    sscanf(t, "%s?%s", t, u->query);
    case "telnet":
	    break;
    default:
	    if (t[0..1] == "//") {
		    t = t[2..];
		    u->slashes = "//";
	    }
    }
    u->body = t;
    sscanf(t, "%s/%s", t, u->resource);
    u->userAtHost = t;
    if (sscanf(t, "%s@%s", s, t)) {
	    if (!sscanf(s, "%s:%s", u->user, u->pass))
		u->user = s;
    }
    u->hostPort = t;
    //if (complete) u->circuit = u->scheme+":"+u->hostPort;
    u->root = u->scheme+":"+u->slashes+u->hostPort;
    if (sscanf(t, "%s:%s", t, s)) {
	    if (!sscanf(s, "%d%s", u->port, u->transport))
		u->transport = s;
    }
    u->host = t;

    P2(("PSYC.parse_uniform", " created %s\n", u))
    return u;
}

class psyc_p {
    string mc, cache;
    mapping (string:mixed) vars;
    mixed data;

    void create(string|void m, string|void d, 
		mapping(string:mixed)|void v ) {
	if (m) mc = m;
	data = d||"";
	vars = v||([]);
    }

    mixed cast(string type) {
	switch(type) {
	case "string":
	    return cache || (cache = .module.render(this_object()));
	case "String.Buffer":
	    return String.Buffer() + (string)this;
	default:
	    return UNDEFINED;
	}
    }

    string _sprintf(int format) {
	switch (format) {
	    case 'O':
		return sprintf("PSYC.psyc_p(%O)", mc);
	    case 's':
		return (string)this;
	}
    }

    mixed `[]=(mixed id, mixed val) {
	cache = UNDEFINED;
	return vars[id] = val;
    }

    mixed `->=(string id, mixed val) {
	cache = UNDEFINED;

	return ::`->=(id, val);
    }

    mixed `[](mixed id) {
	if (has_index(vars, id)) return vars[id];

	return UNDEFINED;
    }
}

string|String.Buffer render(psyc_p o, void|String.Buffer to) {
    String.Buffer p;

    // this could be used to render several psyc-packets/mmp-packets at once
    // into one huge string. should give some decent optimiziation
    if (to)
	p = to;	
    else 
	p = String.Buffer();

    function add = p->add;
    function putchar = p->putchar;

    if (sizeof(o->vars))
	MMP.render_vars(o->vars, p);

    add(o->mc);
    putchar('\n');
    if (o->data) add(o->data);

    if (to) return p; 
    return p->get();
}

// returns a psyc_p or an error string
#ifdef LOVE_TELNET
psyc_p|string parse(string data, string|void linebreak) {
    if (linebreak == 0) linebreak = "\n";
# define LL	linebreak
# define LD	sizeof(linebreak)
#else
psyc_p|string parse(string data) {
# define LL	"\n"
# define LD	1
#endif
    int start, stop, num, lastmod, mod;
    string key, lastkey; 
    mixed lastval, val;

    psyc_p packet = psyc_p();
    packet->vars = ([]);

// may look kinda strange, but i use continue as a goto ,)
// .. also a < is not expensive at all. this could be an != actually...
LINE:while (-1 < stop &&
	    -1 < (stop = (start= (lastmod) ? stop+LD : 0, 
		  search(data, LL, start)))) {

	
	// check for an empty line.. start == stop
	mod = data[start];
	switch(mod) {
	case '=':
	case '+':
	case '-':
	case '?': // not implemented yet.. 
	case ':':
	    num = sscanf(data[start+1 .. stop-1], "%[A-Za-z_]\t%s", key, val);
	    write("psyc-parse: "+key+" => "+val+"\n");
	    if (num == 0) THROW("Blub");
	    if (num == 1) val = 0;
	    else if (key == "") { // list continuation
		if (mod != lastmod) 
		    THROW("improper list continuation");
		if (mod == '-') THROW("diminishing lists is not supported");
		if (stringp(lastval) || intp(lastval)) 
		    lastval = ({ lastval, val });
		else lastval += ({ val });
		continue LINE;
	    }
	    
	    break;
	case '\t': // variable continuation
	    if (!lastmod) THROW("invalid variable continuation");
	    write("psyc-parse:\t+ "+data[start+1 .. stop]);
	    if (arrayp(lastval))
		lastval[-1] += "\n" + data[start+1 .. stop-1];
	    else 
		lastval += "\n" + data[start+1 .. stop-1];
	    continue LINE;
	case '_':
	    // TODO: check mc for sanity
	    packet->mc = data[start .. stop-1];
	    if (strlen(data) > stop+1)
		data = data[stop+1 ..];
	    else data = "";
	    write("mc: "+ packet->mc + "\n");
	    stop = -1;
	    break;
	default:
	    THROW("Unknown variable modifier: " + mod);
	}

	// TODO: modifier unterscheiden
	if (lastmod != 0) {
	    if (lastmod != ':') lastkey = String.int2char(lastmod) + lastkey;
	    packet->vars += ([ lastkey : lastval ]);
	}
	lastmod = mod;
	lastkey = key;
	lastval = val;
    }

    // in case the packet contains 0 data
    if (packet->mc == 0) {
	if (strlen(data) > 1 && data[0] == '_') { 
	    packet->mc = data;
	    packet->data = "";
	} else THROW("Method is missing.");
    } else packet->data = data;  

    return packet;
}

class Server {
    mapping(string:mixed) localhosts;
    mapping(string:object) targets = ([ ]), 
			   contexts = ([ ]), 
			   connecting = ([ ]),
			   connections = ([ ]);
    PSYC.psyc_p circuit_established;
    string bind_to;

    function create_local, create_remote;

    // we could make the verbosity of this putput debug-level dependent
    string _sprintf(int type) {
	if (type == 'O') {
	    if (bind_to)
		return sprintf("PSYC.Server(%s)", bind_to);
	    return "PSYC.Server(0.0.0.0)";
	}
    
	return UNDEFINED;
    }

    void register_target(string t, object o) {
	if (has_index(targets, t)) throw("murks");
	targets[t] = o;
    }

    void unregister_target(string t) {
	m_delete(targets, t);
    }
    
    void register_context(string c, object o) {
	if (has_index(contexts, c)) throw("murks");
	contexts[c] = o;
    }

    void unregister_context(string c) {
	m_delete(contexts, c);
    }
    
    void create(mapping(string:mixed) config) {

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

	if (has_index(config, "create_local")) {
	    create_local = config["create_local"];
	} else {
	    throw("urks");
	}

	if (has_index(config, "create_remote")) {
	    create_local = config["create_remote"];
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

	circuit_established = PSYC.psyc_p("_notice_circuit_established", 
					  "You got connected to %s.\n",
			  ([ "_implementation" : "better than wurstbrote" ]));
    }

    void accept(Stdio.Port lsocket) {
	string peerhost;
	Stdio.File socket;
	socket = lsocket->accept();
	peerhost = socket->query_address();

	connections[peerhost] = MMP.Server(socket, deliver, close);
	connections[peerhost]->send_neg(MMP.mmp_p(circuit_established));
    }

    void close(MMP.Circuit c) {
	m_delete(connections, c->socket->peerhost);
	
	while (!c->isEmpty()) {
	    mixed p;

	    p = c->shift();
	    if (arrayp(p)) {
		p = p[1];
	    }
	    deliver(p, this);
	}
    }

    void connect(int success, Stdio.File so, string id) {
	string peerhost;
	MMP.Circuit c;
	MMP.Utils.Queue q;

	if (!success) {
	    // TODO: send _failures back for every packet in the queue
	    // .. or retry. dont know
	    return;
	}
	
	peerhost = so->query_address();

	c = MMP.Circuit(so, deliver, close);
	c->send_neg(MMP.mmp_p(circuit_established));
	q = connecting[id];
	
	connections[peerhost] = c;

	while (!q->is_empty()) {
	    c->send(q->shift());
	}
	m_delete(connecting, id);
    }

    // simply sends an mmp-packet to host:port
    void send_mmp(string host, string|int port, void|MMP.mmp_p packet) {
	
	void cb(string host, mixed ip, string|int port, void|MMP.mmp_p packet) {
	    Stdio.File so;
	    string id;

	    if (ip == 0) {
		// send a packet back to packet["_source"]... 
		return;
	    }
	    // like socket->query_address()
	    id = ip+" "+(string)port;
	    if (!has_index(connecting, id)) {
		so = Stdio.File();
		if (bind_to)
		    so->open_socket(UNDEFINED, bind_to);
		so->async_connect(ip, port, connect, so, id);
		connecting[id] = MMP.Utils.Queue();
	    }
	    
	    if (packet) connecting[id]->push(packet);
	};
	
	if (has_index(connections, host)) {
	    connections[host]->send(packet);
	    return;
	}

	if (sscanf("%*d.%*d.%*d.%*d", host) != 4) {
	    Protocols.DNS.async_host_to_ip(host, cb, port, packet);
	    return;
	}

	cb(host, host, port, packet);
    }

    void if_localhost(string host, function if_cb, function else_cb, 
		      mixed ... args ) {
	// this is rather bl�de
	P2(("PSYC.Server", "if_localhost(%s, %O, %O, ...)\n", host, if_cb, 
	    else_cb))
	void callback(string host, mixed ip, function if_cb, function else_cb, 
		      mixed ... args ) {

	    // TODO: we need error_handling here!
	    if (!ip) {
		P1(("MMP.Server", "Could not resolve %s.\n", host))
		return;
	    } else {
		P2(("MMP.Server", "%s resolves to %s.\n", host, ip))
	    }
	    if (has_index(localhosts, ip))
		if_cb(@args);
	    else if (else_cb)
		else_cb(@args);
		
	};

	if (has_index(localhosts, host)) {
	    if_cb(@args);
	} else if (sscanf(host, "%*d:%*d:%*d:%*d") == 4) {
	    Protocols.DNS.async_ip_to_host(host, callback, if_cb, else_cb, 
					   @args);
	} else {
	    Protocols.DNS.async_host_to_ip(host, callback, if_cb, else_cb, 
					   @args);
	}
    }

    void unicast(string target, string source, PSYC.psyc_p packet) {
	P2(("PSYC.Server", "%O->unicast(%s, %s, %O)\n", this, target, source, 
	    packet))
	MMP.mmp_p mpacket = MMP.mmp_p(packet, 
				      ([ "_source" : source,
					 "_target" : target ]));
	if (has_index(targets, target)) {
	    targets[target]->msg(mpacket);
	    return;
	}

	// throws.. 
	PSYC.uniform u = PSYC.parse_uniform(target);
	send_mmp(u->host, u->port, mpacket);
    }

    void deliver_remote(MMP.mmp_p packet, string|PSYC.uniform target) {
	P2(("PSYC.Server", "%O->deliver_remote(%O, %s)\n", this, packet, 
	    target))

	if (stringp(target))
	    target = PSYC.parse_uniform(target);

	send_mmp(target->host, target->port||4404, packet);
    }

    void deliver_local(MMP.mmp_p packet, string|PSYC.uniform target) {
	P2(("PSYC.Server", "%O->deliver_local(%O, %s)\n", this, packet, 
	    target))
	if (!has_index(targets, target)) {
	    object o = create_local(target);
	    if (!o) {
		P0(("PSYC.Server", "Could not summon a local object for %s.\n",
		    target))
		return;
	    }
	    targets[target] = o;
	}
	targets[target]->msg(packet);
    }

    // actual routing...
    void deliver(MMP.mmp_p packet, object connection) {
	
	P2(("PSYC.Server", "%O->deliver(%O)\n", this, packet))
	
	string|PSYC.uniform target, source, context;
	// this is maybe the most ... innovative piece of code on this planet
	target = packet["_target"];
	context = packet["_context"];
	source = packet["_source"];

	if (packet->data) {
	    packet->data = PSYC.parse(packet->data);
	} else {
	    P0(("PSYC.Server", "Nothing to deliver.\n"))
	    return;
	}

	switch ((target ? 1 : 0)|
		(source ? 2 : 0)|
		(context ? 4 : 0)) {
	case 3:
	case 1:
	    if (has_index(targets, (string)target)) {
		targets[target]->msg(packet);
		return;
	    } 
	    if (stringp(target)) target = PSYC.parse_uniform(target);

	    if (target->resource) {
		if_localhost(target->host, deliver_local, deliver_remote, 
			     packet, target);
	    } else { // rootmsg
#ifdef DEBUG
		void dummy(MMP.mmp_p p, object c) {
		    P0(("PSYC.Server", "%O lives in crazytown.\n", c))
		};
#else
		function dummy;
#endif
		if_localhost(target->host, rootmsg, dummy, 
			     packet, connection);
	    }
	    break;
	case 2:
	case 0:
	    rootmsg(packet, connection);
	    break;
	case 4:
	    // multicast
	    break;
	case 5:
	    // unicast in context-state..
	    break;
	case 6:
	    // bullshit.. 
	    break;
	case 7:
	    // even more bullshit
	    break;
	default:

	}
	// this is a hack.. (works like psyced)
	if (target) {
	    

	}

    }

    void rootmsg(MMP.mmp_p packet, object connection) {
	
	if (packet->data != 0) {
	    // try to parse psyc here.
	    PSYC.psyc_p message;

	    message = packet->data;

	    switch (message->mc) {
		// ich weiss nichtmehr so genau. in FORK wird das eh alles
		// anders.. ,)
	    case "_notice_circuit_established":
	    case "_status_circuit":
		// auch hier nicht sicher
		connection->activate();
	    }
	} else { // hmm

	}
    }
}