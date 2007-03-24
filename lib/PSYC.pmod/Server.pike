// vim:syntax=lpc
#include <debug.h>
#include <assert.h>

//! PSYC Server class. Does routing and delivery of @[MMP.Packet]s.

mapping(string:mixed) localhosts;
// TODO: i was thinking about changing all those connection based
// stuff to Uniform -> object. the uniform of the root-object of a
// server could then be stored in uniform->super() (name you have to 
// 							think about!)
mapping(object:object)  
		       circuits = ([ ]),
		       wf_circuits = ([ ]), // wf == waiting for
		       vcircuits = ([ ]);
mapping(MMP.Uniform:object) contexts = ([ ]);
mapping(string:MMP.Uniform) unlcache = ([ ]);
PSYC.Packet circuit_established;
string bind_to;
string def_localhost;
PSYC.Root root;
object storage_factory;
function textdb_factory;

function create_local, create_remote, external_deliver_remote, external_deliver_local, create_context;

// to be moved farther down
void activate(MMP.Uniform croot) { // croot == circuit root
    if (croot->handler && croot->handler->circuit) {
	croot->handler->circuit->activate();
	return;
    } else if (has_index(vcircuits, croot)) {
	croot->handler = vcircuits[croot];

	if (croot->handler->circuit) {
	    croot->handler->circuit->activate();
	    return;
	}
    }

    // not sure. activate does not really make sense without
    // a circuit. we might even throw! ... or exit(12).
    // TODO:: throw or exit. ,)
    P0(("PSYC.Server", "%O->activate(%s) failed because the circuit was non-existing??!\n", this, croot))
}

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
    P1(("PSYC.Server", "add_route(%O, %O) as %O.\n", target, circuit, target->root))

    if (!has_index(vcircuits, target->root)) {
	vcircuits[target->root] = MMP.VirtualCircuit(target, this, 0, circuit);
    }
}

//! @param config
//! 	Mandatory settings: 
//! 	@mapping
//! 		@member string "default_localhost"
//! 			The domain this server should use.
//! 		@member function "create_local"
//! 			Callback to be called whenever a local entity needs to be created. 
//! 			Ought to return an object offering a @expr{msg()@} method.
//! 		@member object "storage"
//! 			An instance of a suiting @[PSYC.Storage.Factory] subclass.
//! 		@member array(string) "ports"
//! 			An array of "host:port" strings the server will then try to listen on.
//! 	@endmapping
//! 	Optional settings:
//! 	@mapping
//! 		@member array(string) "localhosts"
//! 			Domains the server should treat as local domains, e.g. himself. Keep in 
//! 			mind that for an @[MMP.Uniform] to be truly local, also the port has to match
//! 			one of those the server is listening on.
//! 		@member function "create_context"
//! 			Callback to be called whenever a local context needs to be created. 
//! 			@b{This has nothing to do with local places/rooms@}. Use "create_local" 
//! 			for that.
//! 		@member function "deliver_remote"
//! 		@member function "deliver_local"
//! 	@endmapping
void create(mapping(string:mixed) config) {

    // TODO: expecting ip:port ... is maybe a bit too much
    // looks terribly ugly..
    //
    // better create root uniforms..

    enforcer(stringp(def_localhost = config["default_localhost"]), 
	    "Default localhost for the PSYC Server missing. (setting: 'default_localhost')");

    if (arrayp(config["localhosts"])) {
	localhosts = ([]);
	foreach (config["localhosts"];;string host) {
	    localhosts[host+":4404"] = 1; 
	}
	localhosts[def_localhost + ":4404"] = 1;
    } else
	localhosts = ([ def_localhost + ":4404" : 1]);



    enforcer(functionp(create_local = config["create_local"]),
	    "Function to create local objects missing. (setting: 'create_local')");

    if (!functionp(create_context = config["create_context"])) {
	object cc(MMP.Uniform context) {
	    return PSYC.Context(this);	    
	};
	create_context = cc;
    }

    enforcer(objectp(storage_factory = config["storage"]), 
	    "Storage factory missing (setting: 'storage')");

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

#ifdef PRIMITIVE_CLIENT
    enforcer(functionp(textdb_factory = config["textdb"]),
	     "Textdb factory missing (setting: 'textdb') but needed for PRIMITIVE_CLIENT. ");
#endif


    enforcer(arrayp(config["ports"]), 
	     "List of ports missing. (setting: 'ports')");
	// more error-checking would be a good idea.
    foreach (config["ports"];; string port) {
	string ip;
	Stdio.Port p;

	localhosts[port] = 1;
	[ip, port] = (port / ":");

	if (!MMP.Utils.Net.is_ip(ip)) {
	    throw(({ sprintf("%O is not a valid IP by my standards, "
			     "cannot bind to that... "
			     "'thing'.\n", ip) }));
	}

	p = Stdio.Port(port, accept, ip);
	bind_to = ip;
	p->set_id(p);
    }

    //set_weak_flag(unlcache, Pike.WEAK_VALUES);

    circuit_established = PSYC.Packet("_notice_circuit_established", 
			  ([ "_implementation" : "PPP" ]),
			  "You got connected to [_source].");
    MMP.Uniform t = get_uniform("psyc://" + def_localhost);
    t->islocal = 1;
    root = PSYC.Root(t, this, storage_factory->getStorage(t));
    t->handler = root;
    PT(("PSYC.Server", "created a new PSYC.Server(%s) with root object %O.\n", root->uni, root))
    // not good for nonstandard port?
}

// CALLBACKS
void accept(Stdio.Port lsocket) {
    Stdio.File socket;
    MMP.Circuit con;

    socket = lsocket->accept();
    con = MMP.Server(socket, route, close, get_uniform);
    circuits[con->peeraddr] = con;
    // create VCircuit for the given peeraddr
    add_route(con->peeraddr, con);
    con->peeraddr->handler = vcircuits[con->peeraddr];
    con->send_neg(MMP.Packet(circuit_established, ([ "_source" : root->uni, "_target" : con->peeraddr ])) );
}

void connect(int success, Stdio.File so, MMP.Uniform id) {
    if (success) {
	MMP.Circuit c = MMP.Active(so, route, close, get_uniform);
	MMP.Utils.Queue q = m_delete(wf_circuits, id);

	circuits[id] = c;

	while (!q->is_empty()) {
	    call_out(q->shift(), 0, c);
	}
    } else {
	// Handle failre here!
	P0(("PSYC.Server", "Connection to %O failed.\n", so))
    }
}

void close(MMP.Circuit c) {
    P0(("PSYC.Server", "%O->close(%O)\n", this, c))
    m_delete(circuits, c->socket->peerhost);
    //c->peeraddr->handler = UNDEFINED;
}

//! @returns
//! 	The object managing the given uniform...string.
//! @note
//! 	You might probably not want to use this, instead contact the entity by sending MMP/PSYC packets.
object get_local(string uni) {

    MMP.Uniform u = get_uniform(uni);

    if (u->handler) return u->handler;
    return u->handler = create_local(u);
}

//! @returns
//!	Returns an unused random local address (to be used for mostly temporary entities that don't need a real name).
//! @param type
//! 	The type of the uniform. Will simply be prepended to the resulting uniforms uniform.
//! @throws
//! 	Will throw if type contains something that better does not go into a uniform.
MMP.Uniform random_uniform(string type) {
    string unl;

    while (has_index(unlcache, unl = (string)(root->uni) + "/$" + type + String.string2hex(random_string(10))));
    
    return get_uniform(unl);
}

//! @returns
//! 	@i{The @}@[MMP.Uniform] object for the uniform given as a string.
//! @throws
//! 	Will throw if the uniform contains something that better does not go into a uniform.
//! @note
//! 	Never ever parse your uniforms manually! @[get_uniform()] uses a
//! 	per server cache to ensure that only one @[MMP.Uniform] for a uniform 
//!	exists in the system at the same time. This allows for cheap checks for
//!	equality by comparing object pointers.
MMP.Uniform get_uniform(string unl) {
    unl = lower_case(unl);

    if (!sizeof(unl)) {
	THROW("ahhhhhh\n");
    }

    if (has_index(unlcache, unl)) {
	P3(("PSYC.Server", "returning cached %O\n", unlcache[unl]))
	return unlcache[unl];
    } else {
	P3(("PSYC.Server", "returning newly created %O\n", unl))
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

void if_localhost(MMP.Uniform candidate, function if_cb, function else_cb,
		  mixed ... args) {
    _if_localhost(candidate, if_cb, else_cb, 0, args);
}

void _if_localhost(MMP.Uniform candidate, function if_cb, function else_cb,
		  int port, array args) {
    // this is rather blöde
    PT(("PSYC.Server", "if_localhost(%s, %O, %O, ...)\n", candidate, if_cb, 
	else_cb))
    void callback(string host, mixed ip) {
	// TODO: we need error_handling here!
	if (!ip) {
	    P1(("MMP.Server", "Could not resolve %s.\n", host))
	} else {
	    P2(("MMP.Server", "%s resolves to %s.\n", host, ip))
	}

	if (ip && has_index(localhosts, ip + ":" + (port ? port : 4404)))
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

			call_out(_if_localhost, 0, get_uniform("psyc://"+target+":"+port), _if_cb, _else_cb,
				 port, ({ }));
		    }
		}
	    }
	} else {
	    Protocols.DNS.async_host_to_ip(candidate->host, callback);
	}
    };

    if (!port) port = candidate->port;

    if (MMP.Utils.Net.is_ip(candidate->host)) {
	if (has_index(localhosts, candidate->host + ":" + (port ? port : 4404))) {
	    if_cb(@args);
	} else {
	    else_cb(@args);
	}
    } else if (!port) {
	MMP.Utils.DNS.async_srv("psyc-server", "tcp", candidate->host, handle_srv);
    } else {
	Protocols.DNS.async_host_to_ip(candidate->host, callback);
    }
}

//! Deliver a @[MMP.Packet] either locally or to a remote host.
//! @param target
//! 	Not to be confused with the MMP variable @expr{_target@}.
//! 	@expr{target@} is used only to find the target host.
//! @note
//! 	If you use convenient @[PSYC.Person] and the like, you most probably 
//! 	don't need to use this directly.
void deliver(MMP.Uniform target, MMP.Packet packet) {
    PT(("PSYC.Server", "%O->deliver(%O, %O)\n", this, target, packet))

    if (target->handler) {
	PT(("PSYC.Server", "Found handler in %O. calling %O.\n", target, target->handler->msg))
	call_out(target->handler->msg, 0, packet);
	return;
    }
    
    if_localhost(target, external_deliver_local, external_deliver_remote, 
		 packet, target);
    
}

void circuit_to(MMP.Uniform target, function(MMP.Circuit:void) cb) {

    if (has_index(circuits, target)) {
	cb(circuits[target]);
    } else if (has_index(wf_circuits, target)) {
	wf_circuits[target]->push(cb);
    } else {
	Stdio.File so;

	wf_circuits[target] = MMP.Utils.Queue();
	wf_circuits[target]->push(cb);

	P2(("PSYC.Server", "Opening a connection to %O.\n", target))

	so = Stdio.File();

	if (bind_to) {
	    enforcer(so->open_socket(UNDEFINED, bind_to),
		     sprintf("Binding to %O failed.\n"));
	}

	so->async_connect(target->host, target->port, connect, so, target);
    }
}

void deliver_remote(MMP.Packet packet, MMP.Uniform root) {
    P2(("PSYC.Server", "%O->deliver_remote(%O, %O)\n", this, packet, root))
    root->islocal = 0;
    root = root->root;
    root->islocal = 0;
    
    P3(("PSYC.Server", "looking in %O for a connection to %s.\n", 
	circuits, root))

    if (has_index(vcircuits, root)) {
	call_out((root->handler = vcircuits[root])->msg, 0, packet);
	return;
    } else {
	MMP.VirtualCircuit vc = MMP.VirtualCircuit(root, this);

	vcircuits[root] = vc;
	vc->msg(packet);
    }
}

void deliver_local(MMP.Packet packet, MMP.Uniform target) {
    P3(("PSYC.Server", "%O->deliver_local(%O, %O)\n", this, packet, 
	target))
    object o = create_local(target);
    target->islocal = 1;

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
    
    P3(("PSYC.Server", "%O->route(%O)\n", this, packet))
    
    MMP.Uniform target, source, context;
    // this is maybe the most ... innovative piece of code on this planet
    target = packet["_target"];
    context = packet["_context"];

    if (!has_index(packet->vars, "_source") && !context) {
	source = connection->peeraddr;
	// THIS IS REMOTE
	packet["_source"] = source;
    } else {
	source = packet["_source"];
    }

    // may be objects already if these are packets coming from a socket that
    // has been closed.
    P3(("PSYC.Server", "routing source: %O, target: %O, context: %O\n", 
	source, target, context))

    switch ((target ? 1 : 0)|
	    (source ? 2 : 0)|
	    (context ? 4 : 0)) {
    case 3:
    case 1:
	P3(("PSYC.Server", "routing %O via unicast to %s\n", packet, 
	    target))

	if (target->handler) {
	    target->handler->msg(packet);
	    return;
	} 

	if (target->resource) {
	    deliver(target, packet);
	} else { // rootmsg
#ifdef DEBUG
	    void dummy(MMP.Packet p) {
		P0(("PSYC.Server", "%O sent us a packet (%O) that apparently does not belong here.\n", p->source(), p))
	    };
#else
	    function dummy;
#endif
	    // wouldnt it be good to have if_localhost check for that
	    // in the uniform on its own?
	    //  being local should never change...
	    if (target->islocal == 1) {
		root->msg(packet);
	    } else if (target->islocal == 0) {
		dummy(packet);
	    } else 
		if_localhost(target, root->msg, dummy, packet);
	}
	break;
    case 2:
    case 0:
	P0(("PSYC.Server", "Broken Packet without _target from %O.\n", source))
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
