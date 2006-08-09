// vim:syntax=lpc
// put that somewhere else.. maybe
//
#define THROW(s)	throw(({ (s), backtrace() }))
#include <debug.h>

class Dummy(mixed...params) { }

Packet reply(Packet m, string|void mc, string|void data, mapping(string:mixed)|void vars) {
    Packet t = Packet(mc, data, vars);

    if (has_index(m->vars, "_tag"))
	t->vars["_tag_reply"] = m->vars["_tag"];

    return t;
}

class Packet {
    string mc, cache;
    mapping (string:mixed) vars;
    string data;

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
#if defined(DEBUG) && DEBUG < 3
		return sprintf("PSYC.Packet(%O, %O)", mc, vars);
#else
		return sprintf("PSYC.Packet(%O)", mc);
#endif
	    case 's':
		return (string)this;
	}
    }

    PSYC.Packet reply(string|void mc, string|void d, 
		mapping(string:mixed)|void v) {
	PSYC.Packet m = PSYC.Packet(mc, d, v);

	if (has_index(vars, "_tag") && sizeof(vars["_tag"])) {
	    m["_tag_reply"] = vars["_tag"]; 
	}

	return m;
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
	return vars[id];
    }
}

#if 0
// evil parser
string psyctext(PSYC.Packet m) {
    String.Buffer buf = String.Buffer(); 

    string data = m->data;
    
    int opened;
    int start, stop;

    while (stop < sizeof(data)-1) {
	start = stop;
	if (opened) {
	    stop = search(data, "]", start);
	} else {
	    stop = search(data, "[", start);
	}

	if (stop == -1 || sizeof(data)-1 <= stop+1) {
	    buf->add(data[start..]);
	    break;
	}

	if (opened && data[start+1] == '_' 
	&& has_index(m->vars, data[start+1..stop-1])) {
	    buf->add(m->vars[data[start+1..stop-1]]);
	} else {
	    buf->add(data[start..stop]);
	}

	opened ^= 1;
    }

    return buf->get();
}
#endif

string psyctext(MMP.Packet p) {
    mapping v;
    string tmp;

    if (p->vars) {
	if (!v) v = ([]);
	v += p->vars;
    }

    if (p->data && p->data->vars) {
	if (!v) v = ([]);
	v += p->data->vars;
    }

    if (p->data && search(p->data->mc, "_message") == 0) {

	tmp = "[_source_relay] says: [_data]";
	if (!v) {
	    v = ([ "_data" : p->data->data ]);
	} else {
	    v["_data"] = p->data->data;
	}
    } else {
	tmp =  p->data ? p->data->data : "--> no text <--";
    }


    if (v) {
	return PSYC.Text.psyctext(tmp, v);
    }

    return tmp;
}

string|String.Buffer render(Packet o, void|String.Buffer to) {
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

// returns a Packet or an error string
#ifdef LOVE_TELNET
Packet parse(string data, string|void linebreak) {
    if (linebreak == 0) linebreak = "\n";
# define LL	linebreak
# define LD	sizeof(linebreak)
#else
Packet parse(string data) {
# define LL	"\n"
# define LD	1
#endif
    int start, stop, num, lastmod, mod;
    string key, lastkey; 
    mixed lastval, val;

    Packet packet = Packet();
    packet->vars = ([]);
    packet->cache = data;

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
	    num = sscanf(data[start+1 .. stop-1], "%[A-Za-z_]"
#ifdef LOVE_TELNET
			 "%*[ \t]"
#else
			 "\t"
#endif
			 "%s", key, val);
	    P2(("PSYC.parse", "parsed variable: %s => %O\n", key, val))
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
	    P2(("PSYC.parse", "parsed variable continuation: %s\n", 
		data[start+1 .. stop]))
	    if (arrayp(lastval))
		lastval[-1] += "\n" + data[start+1 .. stop-1];
	    else 
		lastval += "\n" + data[start+1 .. stop-1];
	    continue LINE;
	case '_':
	    // TODO: check mc for sanity
	    packet->mc = data[start .. stop-1];
	    if (strlen(data) > stop+LD)
		data = data[stop+LD ..];
	    else data = "";
	    P2(("PSYC.parse", "parsed method: %s\n", packet->mc))
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
    mapping(string:object) contexts = ([ ]), 
			   connecting = ([ ]), // pending, unusable connections
			   connections = ([ ]),// up and running connections
			   routes = ([ ]);     // connections routing for for
					       // somebody else
    mapping(string:MMP.Uniform) unlcache = ([ ]);
    PSYC.Packet circuit_established;
    string bind_to;
    string def_localhost;

    function create_local, create_remote;
    object server; // hack for contextMaster

    inherit ContextManager;

    // we could make the verbosity of this putput debug-level dependent
    string _sprintf(int type) {
	if (type == 'O') {
	    if (bind_to)
		return sprintf("PSYC.Server(%s)", bind_to);
	    return "PSYC.Server(0.0.0.0)";
	}
    
	return UNDEFINED;
    }

    // these contexts are local context slaves.. for remote rooms. and also 
    // context slaves for local rooms. we should not make any difference really
    void register_context(string|MMP.Uniform c, object o) {
	if (has_index(contexts, (string)c)) throw("murks");
	contexts[(string)c] = o;
    }

    void unregister_context(string|MMP.Uniform c) {
	m_delete(contexts, (string)c);
    }

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

	if (has_index(config, "default_localhost")) {
	    def_localhost = config["default_localhost"];  
	}

#if 0
	if (has_index(config, "create_remote")
	    && functionp(create_remote = config["create_remote"])) {
	} else {
	    throw("urks");
	}
#endif

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

	//set_weak_flag(unlcache, Pike.WEAK_VALUES);

	circuit_established = PSYC.Packet("_notice_circuit_established", 
					  "You got connected to %s.\n",
			  ([ "_implementation" : "better than wurstbrote" ]));
	server = this;
    }

    // CALLBACKS
    void accept(Stdio.Port lsocket) {
	string peerhost;
	Stdio.File socket;
	socket = lsocket->accept();
	peerhost = socket->query_address();

	connections[peerhost] = MMP.Server(socket, route, close, get_uniform);
	connections[peerhost]->send_neg(MMP.Packet(circuit_established));
    }

    void connect(int success, Stdio.File so, MMP.Utils.Queue q, 
		 MMP.Uniform target, string id) {
	string peerhost;
	MMP.Circuit c;

	if (!success) {
	    P0(("PSYC.Server", "Connection to %O failed (%d).\n", id,
		so->errno()))
	    // TODO: send _failures back for every packet in the queue
	    // .. or retry. dont know
	    return;
	}
	
	peerhost = so->query_address();

	P2(("PSYC.Server", "get_uniform: %O\n", get_uniform))
	c = MMP.Active(so, route, close, get_uniform);
	target->handler = c;
	c->send_neg(MMP.Packet(circuit_established));
	
	connections[peerhost] = c;

	while (!q->isEmpty()) {
	    c->msg(q->shift());
	}
	m_delete(connecting, id);
    }

    void close(MMP.Circuit c) {
	P0(("PSYC.Server", "%O->close(%O)\n", this, c))
	m_delete(connections, c->socket->peerhost);
	m_delete(routes, c->socket->peerhost);
	c->peeraddr->handler = UNDEFINED;
	
	
	while (!c->isEmpty()) {
	    mixed p = c->shift();

	    if (arrayp(p)) {
		p = p[1];
	    }
	    // TODO: this is maybe crap, but routing is worse. the target
	    // this packets has once been send() to may be different
	    // from the peeraddr
	    deliver_remote(p, c->peeraddr);
	    sleep(2);
	}
    }

    // returns the handler for a uniform
    object get_local(string uni) {

	MMP.Uniform u = get_uniform(uni);

	if (u->handler) return u->handler;
	return u->handler = create_local(u);
    }

    MMP.Uniform get_uniform(string unl) {
	unl = lower_case(unl);

	if (has_index(unlcache, unl)) {
	    P2(("PSYC.Server", "returning cached %O\n", unlcache[unl]))
	    return unlcache[unl];
	} else {
	    P2(("PSYC.Server", "returning newly created %O\n", unl))
	    return unlcache[unl] = MMP.Uniform(unl);
	}
    }

    void if_localhost(string host, function if_cb, function else_cb, 
		      mixed ... args ) {
	// this is rather blöde
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

    // obsolete
    void unicast(MMP.Uniform target,MMP.Uniform source, 
		 PSYC.Packet packet) {
	P2(("PSYC.Server", "%O->unicast(%O, %O, %O)\n", this, target, source, 
	    packet))
	MMP.Packet mpacket = MMP.Packet(packet, 
				      ([ "_source" : source,
					 "_target" : target ]));
	deliver(target, mpacket);
    }

    void deliver(MMP.Uniform target, MMP.Packet packet) {
	P2(("PSYC.Server", "%O->deliver(%O, %O)\n", this, target, packet))

	if (target->handler) {
	    target->handler->msg(packet);
	    return;
	}
	
	if_localhost(target->host, deliver_local, deliver_remote, 
		     packet, target);
	
    }

    void deliver_remote(MMP.Packet packet, MMP.Uniform target) {
	P2(("PSYC.Server", "%O->deliver_remote(%O, %O)\n", this, packet, target))
	string host = target->host;
	int port = target->port || 4404;
	string peerhost = host + " " + (string)port;
	
	void cb(string host, mixed ip, string|int port, void|MMP.Packet packet) {
	    Stdio.File so;
	    MMP.Utils.Queue q;
	    string id;

	    if (ip == 0) {
		P0(("PSYC.Server", "Could not resolve %O.\n", packet))
		// send a packet back to packet["_source"]... 
		return;
	    }
	    // like socket->query_address()
	    id = ip+" "+(string)port;
	    if (!has_index(connecting, id)) {
		P2(("PSYC.Server", "Opening a connection to %O.\n", id))
		so = Stdio.File();
		connecting[id] = q = MMP.Utils.Queue();
		if (bind_to)
		    so->open_socket(UNDEFINED, bind_to);
		P2(("PSYC.Server", "so->async_connect(%O, %O, %O, %O, %O, %O, %O);\n", ip, port, connect, so, q, target, id))
		so->async_connect(ip, port, connect, so, q, target, id);
	    }
	    
	    if (packet) connecting[id]->push(packet);
	};
	
	P2(("PSYC.Server", "looking in %O for a connection to %s.\n", 
	    connections, peerhost))

	if (has_index(connections, peerhost)) {
	    (target->handler = connections[peerhost])->msg(packet);

	    return;
	} else if (has_index(routes, peerhost)) {
	    (target->handler = routes[peerhost])->msg(packet);

	    return;
	}

	if (sscanf("%*d.%*d.%*d.%*d", host) != 4) {
	    Protocols.DNS.async_host_to_ip(host, cb, port, packet);

	    return;
	}

	cb(host, host, port, packet);
    }

    void deliver_local(MMP.Packet packet, MMP.Uniform target) {
	P2(("PSYC.Server", "%O->deliver_local(%O, %O)\n", this, packet, 
	    target))
	object o = create_local(target);

	if (!o) {
	    P0(("PSYC.Server", "Could not summon a local object for %O.\n",
		target))
	    return;
	}

	target->handler = o;
	target->handler->msg(packet);
    }

    // actual routing...
    void route(MMP.Packet packet, object connection) {
	
	P2(("PSYC.Server", "%O->route(%O)\n", this, packet))
	
	MMP.Uniform target, source, context;
	// this is maybe the most ... innovative piece of code on this planet
	target = packet["_target"];
	context = packet["_context"];
	if (!has_index(packet->vars, "_source") && !context) {
	    source = connection->peeraddr;
	    // THIS IS REMOTE
	    packet["_source"] = source;
	} else source = packet["_source"];

	// may be objects already if these are packets coming from a socket that
	// has been closed.
	if (packet->data) { 
#ifdef LOVE_TELNET
	    packet->data = PSYC.parse(packet->data, connection->dl);
#else
	    packet->data = PSYC.parse(packet->data);
#endif
	} else {
	    P0(("PSYC.Server", "Nothing to route.\n"))
	    return;
	}

	P2(("PSYC.Server", "routing source: %O, target: %O, context: %O\n", 
	    source, target, context))

	switch ((target ? 1 : 0)|
		(source ? 2 : 0)|
		(context ? 4 : 0)) {
	case 3:
	case 1:
	    P2(("PSYC.Server", "routing %O via unicast to %s\n", packet, 
		target))

	    if (target->handler) {
		target->handler->msg(packet);
		return;
	    } 

	    if (target->resource) {
		deliver(target, packet);
	    } else { // rootmsg
#ifdef DEBUG
		void dummy(MMP.Packet p, object c) {
		    P0(("PSYC.Server", "%O lives in crazytown.\n", c))
		};
#else
		function dummy;
#endif
		if_localhost(target->host, msg, dummy, 
			     packet, connection);
	    }
	    break;
	case 2:
	case 0:
	    msg(packet);
	    break;
	case 4:
	    P2(("PSYC.Server", "routing multicast message %O to local %s\n", packet, context))
	    if (has_index(contexts, (string)context)) {
		contexts[(string)context]->msg(packet);
	    }
	    break;
	case 5:
	    // unicast in context-state..
	    // TODO: we dont know how to handle different states right now..
	    // maybe it can be done in Uni.pmod but then we would have to 
	    // double check
	    P0(("PSYC.Server", "unimplemented routing scheme (%d)\n", 5))
	    break;
	case 6:
	    P0(("PSYC.Server", "unimplemented routing scheme (%d)\n", 6))
	    // bullshit.. 
	    break;
	case 7:
	    P0(("PSYC.Server", "unimplemented routing scheme (%d)\n", 7))
	    // even more bullshit
	    break;
	}
    }

    void msg(MMP.Packet packet, void|object connection) {

	::msg(packet);

	MMP.Uniform source = packet["_source"];
	if (!connection) {
	    connection = source->handler;
	}
	
	P2(("PSYC.Server", "rootmsg(%O) from %O\n", packet, connection))
	if (packet->data != 0) {
	    PSYC.Packet message = packet->data;

	    switch (message->mc) {
		// ich weiss nichtmehr so genau. in FORK wird das eh alles
		// anders.. ,)
	    case "_notice_circuit_established":
		routes[source->host+" "+(string)(source->port||4404)] = connection;
	    case "_status_circuit":
		source->handler = connection;
		// auch hier nicht sicher
		connection->activate();
		break;
	    }
	} else { // hmm

	}
    }
}
