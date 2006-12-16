#include <debug.h>

mapping(string:mixed) localhosts;
// TODO: i was thinking about changing all those connection based
// stuff to Uniform -> object. the uniform of the root-object of a
// server could then be stored in uniform->super() (name you have to 
// 							think about!)
mapping(string:object)  
		       circuits = ([ ]),
		       wf_circuits = ([ ]), // wf == waiting for
		       vcircuits = ([ ]);
mapping(MMP.Uniform:object) contexts = ([ ]);
mapping(string:MMP.Uniform) unlcache = ([ ]);
PSYC.Packet circuit_established;
string bind_to;
string def_localhost;
PSYC.Root root;

function create_local, create_remote, external_deliver_remote, external_deliver_local, create_context;

// we could make the verbosity of this putput debug-level dependent
string _sprintf(int type) {
    if (type == 'O') {
	if (bind_to)
	    return sprintf("PSYC.Server(%s)", bind_to);
	return "PSYC.Server(0.0.0.0)";
    }

    return UNDEFINED;
}

// MULTICAST SORTOF
void register_context(MMP.Uniform c, object o) {
    if (has_index(contexts, c)) throw(({"murks"}));
    contexts[c] = o;
}

void unregister_context(MMP.Uniform c) {
    m_delete(contexts, c);
}

object get_context(MMP.Uniform c) {
    if (has_index(contexts, c)) {
	return contexts[c];
    }

    return contexts[c] = create_context(c);
}

void insert(MMP.Uniform context, MMP.Uniform guz) {
    get_context(context)->insert(guz);
}

void add_route(MMP.Uniform target, object circuit) {
    int port = target->port;
    string peerhost = target->host + (port ? " " + port : "");

    if (!has_index(vcircuits, peerhost)) {
	vcircuits[peerhost] = MMP.VirtualCircuit(target, this, circuit);
    }
}

void create(mapping(string:mixed) config) {

    // TODO: expecting ip:port ... is maybe a bit too much
    // looks terribly ugly..
    if (has_index(config, "localhosts")) { 
	localhosts = config["localhosts"];
    } else {
	localhosts = ([ ]);
    }

    if (has_index(config, "create_local") 
	&& functionp(create_local = config["create_local"])) {
    } else {
	throw(({"urks"}));
    }

    if (has_index(config, "create_context") 
	&& functionp(create_context = config["create_context"])) {
    } else {
	object cc(MMP.Uniform context) {
	    return PSYC.Context(this);	    
	};

	create_context = cc;
    }

    if (has_index(config, "default_localhost")) {
	def_localhost = config["default_localhost"];  
    } else {
	throw(({"aaahahha"}));
    }

    if (has_index(config, "deliver_remote")) {
	external_deliver_remote = config["deliver_remote"];
    } else {
	external_deliver_remote = deliver_remote; 
    }

    if (has_index(config, "deliver_local")) {
	external_deliver_local = config["deliver_local"];
    } else {
	external_deliver_local = deliver_local; 
    }

    if (has_index(config, "ports")) {
	// more error-checking would be a good idea.
	foreach (config["ports"];; string port) {
	    string ip;
	    Stdio.Port p;

	    [ip, port] = (port / ":");

	    if (!MMP.Utils.Net.is_ip(ip)) {
		throw(({ sprintf("%O is not a valid IP by my standards, "
				 "cannot bind to that... "
				 "'thing'.\n", ip) }));
	    }

	    p = Stdio.Port(port, accept, ip);
	    localhosts[port] = 1;
	    bind_to = ip;
	    p->set_id(p);
	}
    } else throw(({ "help!" }));

    //set_weak_flag(unlcache, Pike.WEAK_VALUES);

    circuit_established = PSYC.Packet("_notice_circuit_established", 
			  ([ "_implementation" : "better than wurstbrote" ]),
			  "You got connected to [_source].");
    MMP.Uniform t = get_uniform("psyc://" + def_localhost);
    t->islocal = 1;
    t->handler = this;
    // not good for nonstandard port?
    root = PSYC.Root(t, this, PSYC.DummyStorage());
}

// CALLBACKS
void accept(Stdio.Port lsocket) {
    string peerhost;
    Stdio.File socket;
    MMP.Server con;

    socket = lsocket->accept();
    peerhost = socket->query_address();

    circuits[peerhost] = (con = MMP.Server(socket, route, close, get_uniform));
    con->send_neg(MMP.Packet(circuit_established, ([ "_source" : root->uni, "_target" : con->peeraddr ])) );
}

void connect(int success, Stdio.File so, string id) {
    MMP.Circuit c = MMP.Active(so, route, close, get_uniform);
    MMP.Utils.Queue q = m_delete(wf_circuits, id);

    if (success) {
	circuits[id] = c;
    }

    while (!q->is_empty()) {
	call_out(q->shift(), 0, c);
    }
}

void close(MMP.Circuit c) {
    P0(("PSYC.Server", "%O->close(%O)\n", this, c))
    m_delete(circuits, c->socket->peerhost);
    m_delete(routes, c->socket->peerhost);
    //c->peeraddr->handler = UNDEFINED;
}

// returns the handler for a uniform
object get_local(string uni) {

    MMP.Uniform u = get_uniform(uni);

    if (u->handler) return u->handler;
    return u->handler = create_local(u);
}

MMP.Uniform random_uniform(string type) {
    string unl;

    while (has_index(unlcache, unl = (string)root->uni + "$" + type + String.string2hex(random_string(10))));
    
    return get_uniform(unl);
}

MMP.Uniform get_uniform(string unl) {
    unl = lower_case(unl);

    if (has_index(unlcache, unl)) {
	P2(("PSYC.Server", "returning cached %O\n", unlcache[unl]))
	return unlcache[unl];
    } else {
	P2(("PSYC.Server", "returning newly created %O\n", unl))
	MMP.Uniform t = MMP.Uniform(unl);

	if (t->resource) {
	    t->root = get_uniform(t->scheme+":"+t->slashes+t->hostPort);
	} else { // cycle cycle cycle
	    t->root = t;
	}

	if (t->channel) {
	    t->super = get_uniform(t->scheme + t->slashes + t->body + "/" + t->obj);
	}

	return unlcache[unl] = t;
    }
}

void if_localhost(string host, function if_cb, function else_cb,
		  mixed ... args) {
    _if_localhost(host, if_cb, else_cb, 0, args);
}

void _if_localhost(string host, function if_cb, function else_cb,
		  int port, array args) {
    // this is rather blöde
    P2(("PSYC.Server", "if_localhost(%s, %O, %O, ...)\n", host, if_cb, 
	else_cb))
    void callback(string host, mixed ip) {
	// TODO: we need error_handling here!
	if (!ip) {
	    P1(("MMP.Server", "Could not resolve %s.\n", host))
	} else {
	    P2(("MMP.Server", "%s resolves to %s.\n", host, ip))
	}

	if (ip && has_index(localhosts, ip + ":" + port))
	    if_cb(@args);
	else if (else_cb)
	    else_cb(@args);
    };

    void handle_srv(string query, array(mapping)|int result) {
	if (arrayp(result) && sizeof(result)) {
	    int done, count;

	    void _if_cb() {
		if (!done) {
		    done = 1;
		    count--;
		    if_cb(@args);
		}
	    };

	    void _else_cb() {
		if (!done && !--count) {
		    else_cb(@args);
		}
	    };

	    multiset seen = (<>);

	    foreach (result;; mapping answer) {
		string target = answer->target;
		int port = answer->port;

		if (stringp(target) && sizeof(target)) {
		    if (!has_index(seen, target + ":" + port)) {
			seen[target + ":" + port]++;
			count++;

			call_out(_if_localhost, 0, target, _if_cb, _else_cb,
				 port, ({ }));
		    }
		}
	    }
	} else {
	    Protocols.DNS.async_host_to_ip(host, callback);
	}
    };

    if (MMP.Utils.Net.is_ip(host)) {
	if (has_index(localhosts, host + ":" + port)) {
	    if_cb(@args);
	} else {
	    else_cb(@args);
	}
    } else if (!port) {
	MMP.Utils.DNS.async_srv("psyc-server", "tcp", host, handle_srv);
    } else {
	Protocols.DNS.async_host_to_ip(host, callback);
    }
}

void deliver(MMP.Uniform target, MMP.Packet packet) {
    P2(("PSYC.Server", "%O->deliver(%O, %O)\n", this, target, packet))

    if (target->handler) {
	call_out(target->handler->msg, 0, packet);
	return;
    }
    
    if_localhost(target->host, external_deliver_local, external_deliver_remote, 
		 packet, target);
    
}

void circuit_to(string ip, int port, function(MMP.Circuit:void) cb) {
    string id = ip + " " + port;

    if (has_index(circuits, id)) {
	cb(circuits[id]);
    } else if (has_index(wf_circuits, id)) {
	wf_circuits[id]->push(cb);
    } else {
	Stdio.File so;

	wf_circuits[id] = MMP.Utils.Queue();
	wf_circuits[id]->push(cb);

	P2(("PSYC.Server", "Opening a connection to %O.\n", id))

	so = Stdio.File();

	if (bind_to) so->open_socket(UNDEFINED, bind_to);

	so->async_connect(ip, port, connect, so, id);
    }
}

void deliver_remote(MMP.Packet packet, MMP.Uniform target) {
    P2(("PSYC.Server", "%O->deliver_remote(%O, %O)\n", this, packet, target))
    string host = target->host;
    int port = target->port;
    string peerhost = host + (port ? " " + port : "");
    
    P2(("PSYC.Server", "looking in %O for a connection to %s.\n", 
	circuits, peerhost))

    if (has_index(vcircuits, peerhost)) {
	call_out((target->handler = vcircuits[peerhost])->msg, 0, packet);
	return;
    /* // TODO:: someone fix the routes!
    } else if (has_index(routes, peerhost)) {
	call_out((target->handler = routes[peerhost])->msg, 0, packet);
	return;
    */
    } else {
	MMP.VirtualCircuit vc = MMP.VirtualCircuit(target, this);

	vcircuits[peerhost] = vc;
	vc->msg(packet);
    }
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
    call_out(o->msg, 0, packet);
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
	    if_localhost(target->host, root->msg, dummy, 
			 packet, connection);
	}
	break;
    case 2:
    case 0:
	PT(("PSYC.Server", "Broken Packet without _target from %O.\n", source))
	root->msg(packet);
	break;
    case 4:
	P2(("PSYC.Server", "routing multicast message %O to local %s\n", 
	    packet, context))
	if (has_index(contexts, context)) {
	    contexts[context]->msg(packet);
	} else {
	    P0(("PSYC.Server", "<F8>hzt noone distributing messages in %O\n", 
		context))
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
