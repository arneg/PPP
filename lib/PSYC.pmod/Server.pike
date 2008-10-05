// vim:syntax=lpc
#include <new_assert.h>

//! PSYC Server class. Does routing and delivery of @[MMP.Packet]s.

inherit MMP.Utils.Debug;

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
mapping params;
PSYC.Packet circuit_established;
string bind_to;
string def_localhost;
PSYC.Root root;
object storage_factory;
function textdb_factory;

function create_local, create_remote, external_deliver_remote, external_deliver_local, create_context,
	 debug;

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
    do_throw("%O->activate(%s) failed because the circuit was non-existing??!\n", this, croot);
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

void register_context(MMP.Uniform c, object o) {
    if (has_index(contexts, c)) throw(({"murks"}));
    contexts[c] = o;
}

void unregister_context(MMP.Uniform c) {
    m_delete(contexts, c);
}

//! Return the Context Distribution object that does handle @expr{c@} locally.
//! If there is no object at the moment for the given context, one is 
//! automatically created using the "create_context" callback given on 
//! @[create()]. If none has been specified in @[create()] by 
//! default @[PSYC.Context] objects are created.
//! @param c
//! 	The address of the Context.
object get_context(MMP.Uniform c) {
    if (has_index(contexts, c)) {
	return contexts[c];
    }

    return contexts[c] = create_context(c);
}

void insert(MMP.Uniform context, MMP.Uniform guz) {
    get_context(context)->insert(guz);
}

//! This method basically creates a @[MMP.VirtualCircuit] for the given address. It will try
//! to reconnect if @expr{circuit@} is closed. Therefore it is not wise to
//! use a circuit that does not actually point to the Root of @expr{target@} as the
//! @[MMP.VirtualCircuit] will connect to a different one after close.
//! @param target
//! 	Target to which the route should point to. 
//! @param circuit
//! 	The MMP.Circuit (or something implementing the same API) which should be used
//! 	for the route. 
//! @note
//! 	Warning: Use this method only if you know what you are doing. really.
void add_route(MMP.Uniform target, object circuit) {
    debug("routing", 3, "add_route(%O, %O) as %O.\n", target, circuit, target->root);

    if (!has_index(vcircuits, target->root)) {
	vcircuits[target->root] = MMP.VirtualCircuit(target, this, failure_delivery, 0, circuit);
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
//! 		@member string "bind_to"
//! 			Ip to bind to. Has to be specified in case no ports have been given for 
//! 			connects. If ports given, the first ip is used to bind to. 
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

    if (!config["debug"]) {
	config["debug"] = MMP.Utils.DebugManager(); 
    }

    ::create(config["debug"]);
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
	    return PSYC.Context(params);	    
	};
	create_context = cc;
    }

    enforcer(objectp(storage_factory = config["storage"]), 
	    "Storage factory missing (setting: 'storage')");

    params = ([
	"server" : this,
	"debug" : config["debug"],
	"storage_factory" : storage_factory,
    ]);

    if (!storage_factory->codec_object) {
	storage_factory->codec_object = PSYC.Codec(params);
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


#ifdef PRIMITIVE_CLIENT
    enforcer(functionp(textdb_factory = config["textdb"]),
	     "Textdb factory missing (setting: 'textdb') but needed for PRIMITIVE_CLIENT. ");
#endif

    if (stringp(config["bind_to"])) {
	enforcer(MMP.Utils.Net.is_ip(config["bind_to"]),
		 sprintf("Malformed ip (%s) address given in \"bind_to\".", config["bind_to"]));
	bind_to = config["bind_to"];
    }

    // more error-checking would be a good idea.
    if (arrayp(config["ports"])) foreach (config["ports"];; string port) {
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
	if (!bind_to) bind_to = ip;
	p->set_id(p);
    } else if (!bind_to) {
	if (has_index(config, "bind_to"))
	    throw(({"'ports' are expected to be an array of ips.\n"}));
	throw(({"You either must specify ports to bind to or at least an ip (\"bind_to\") to bind outgoing connections to.\n"}));
    }

    //set_weak_flag(unlcache, Pike.WEAK_VALUES);

    circuit_established = PSYC.Packet("_notice_circuit_established", 
			  ([ "_implementation" : "PPP" ]),
			  "You got connected to [_source].");
    MMP.Uniform t = get_uniform("psyc://" + def_localhost);
    werror("%O\n", t);
    t->islocal = 1;
    root = create_local(params + ([ "uniform" : t ]));
    t->handler = root;
    werror("%O\n", root);
    debug("local_objects", 8, "created a new PSYC.Server(%s) with root object %O.\n", root->uni, root);
    // not good for nonstandard port?
}

// CALLBACKS
void accept(Stdio.Port lsocket) {
    Stdio.File socket;

    socket = lsocket->accept();

    add_socket(socket);
}

//! Add a socket by hand. Use this only if your port handling is controlled by 
//! some other application, e.g. Roxen.
//! 
//! @param socket
//! 	Socket to be added. Has to be subclass of Stdio.File offering
//! 	@[Stdio.File->query_address()], etc.
void add_socket(Stdio.File socket) {
    MMP.Circuit con;
    con = MMP.Server(socket, check, close, get_uniform);
    circuits[con->peeraddr] = con;
    // create VCircuit for the given peeraddr
    add_route(con->peeraddr, con);
    con->peeraddr->handler = vcircuits[con->peeraddr];
    con->send_neg(MMP.Packet(circuit_established, ([ "_source" : root->uni, "_target" : con->peeraddr ])) );
}

void connect(int success, Stdio.File so, MMP.Uniform id) {
    MMP.Circuit c = 0;

    if (success) {
	c = MMP.Active(so, check, close, get_uniform);

	circuits[c->peeraddr] = c;

    } else {
	debug("routing", 2, "Connection to %O failed.\n", so);
    }

    MMP.Utils.Queue q = m_delete(wf_circuits, id);

    while (!q->is_empty()) {
	MMP.Utils.invoke_later(q->shift(), c);
    }
}

void close(MMP.Circuit c) {
    debug("routing", 5, "%O->close(%O)\n", this, c);
    m_delete(circuits, c->peeraddr);
    //c->peeraddr->handler = UNDEFINED;
}

object get_storage(MMP.Uniform uni) {

    if (!uni->is_local()) {
	do_throw("we have no storage for remote object %O.\n", uni);
    }

    return storage_factory->getStorage(uni);
}

//! @returns
//! 	The object managing the given uniform...string.
//! @note
//! 	You might probably not want to use this, instead contact the entity by sending MMP/PSYC packets.
object get_local(string uni) {

    MMP.Uniform u = get_uniform(uni);

    if (u->handler) return u->handler;
    return u->handler = create_local(params + ([ "uniform" : u ]));
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
	do_throw("ahhhhhh\n");
    }

    if (has_index(unlcache, unl)) {
	return unlcache[unl];
    } else {
	MMP.Uniform t = MMP.Uniform(unl);

	if (t->resource) {
	    t->root = get_uniform(t->scheme+":"+t->slashes+t->hostPort);
	    t->root->reconnectable = t->reconnectable;
	} else { // cycle cycle cycle
	    t->root = t;
	}

	if (t->channel) {
	    t->super = get_uniform(t->scheme + ":" + t->slashes + t->hostPort + "/" + t->obj);
	}

	return unlcache[unl] = t;
    }
}

MMP.Uniform atom_decode_uniform(Serialization.Atom a, int|program ptype, object reactor) {
    MMP.Uniform uni;
    if (ptype != MMP.Uniform) return 0;
    if (mixed err = catch {uni = get_uniform(a->data);}) {
	return 0;
    }

    return uni;
}

Serialization.Atom atom_encode_uniform(MMP.Uniform uni, string type, object reactor) {
    return MMP.atom_encode_uniform(uni, type, reactor);
}

void if_localhost(MMP.Uniform candidate, function if_cb, function else_cb,
		  mixed ... args) {
    _if_localhost(candidate, if_cb, else_cb, 0, args);
}

void _if_localhost(MMP.Uniform candidate, function if_cb, function else_cb,
		  int port, array args) {
    // this is rather blöde
    debug("dns", 4, "if_localhost(%s, %O, %O, ...) looking in %O\n", candidate, if_cb, 
	else_cb, localhosts);
    void callback(string host, mixed ip) {
	// TODO: we need error_handling here!
	if (!ip) {
	    debug("dns", 3, "Could not resolve %s.\n", host);
	} else {
	    debug("dns", 5, "%s resolves to %s.\n", host, ip);
	}

	if (ip && has_index(localhosts, ip + ":" + (port ? port : 4404)))
	    if_cb(@args);
	else if (else_cb)
	    else_cb(@args);
    };


    if (!port) port = candidate->port;

    if (candidate->is_local() || 
	has_index(localhosts, candidate->host + ":" + (port ? port : 4404))) {
	if_cb(@args);
    } else if (MMP.Utils.Net.is_ip(candidate->host)) {
	else_cb(@args);
    } else if (!port) {
	void handle_srv(string query, array(mapping)|int reply) {
	    array(mapping)|int result;

	    result = objectp(reply) ? reply->result : reply;

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
    debug("packet_flow", 4, "%O->deliver(%O, %O)\n", this, target, packet);

    if (target->handler) {
	debug("packet_flow", 5, "Found handler in %O. calling %O->msg().\n", target, target->handler);
	MMP.Utils.invoke_later(target->handler->msg, packet);
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
    } else if (target->reconnectable) {
	Stdio.File so;

	wf_circuits[target] = MMP.Utils.Queue();
	wf_circuits[target]->push(cb);

	so = Stdio.File();

	if (bind_to) {
	    enforcer(so->open_socket(UNDEFINED, bind_to),
		     sprintf("Binding to %O failed.\n", bind_to));
	}

	so->async_connect(target->host, target->port ? target->port : 4404, connect, so, target);
    } else { // negative port.. react
	cb(0);	
    }
}


void failure_delivery(MMP.Uniform target, MMP.Packet p, void|mixed reason) {
    if (objectp(p->data)) {
	if (!PSYC.abbrev(p->data->mc, "_failure_delivery")) {
	    PSYC.Packet reply = p->data->reply("_failure_delivery", 
					       ([
					"_id" : p->id(),
					"_location" : target,
						 ]));
	    root->sendmmp(p->tsource(), MMP.Packet(reply));
	} else {
	    debug("routing", 0, "a _failure_delivery could not be delivered: %O, %O\n", p, reason);
	}
    }
}

void deliver_remote(MMP.Packet packet, MMP.Uniform root) {
    debug("packet_flow", 5, "%O->deliver_remote(%O, %O)\n", this, packet, root);
    root->islocal = 0;
    root = root->root;
    root->islocal = 0;
    
    if (has_index(vcircuits, root)) {
	MMP.Utils.invoke_later((root->handler = vcircuits[root])->msg, packet);
	return;
    } else {
	MMP.VirtualCircuit vc = MMP.VirtualCircuit(root, this, failure_delivery);

	vcircuits[root] = vc;
	vc->msg(packet);
    }
}

void deliver_local(MMP.Packet packet, MMP.Uniform target) {
    debug("packet_flow", 5, "%O->deliver_local(%O, %O)\n", this, packet, 
	target);
    target->islocal = 1;
    object o = create_local(params + ([ "uniform" : target ]));

    if (!o) {
	debug("local_objects", 0, "Could not summon a local object for %O.\n",
	    target);
	failure_delivery(target, packet);	
	return;
    }

    target->handler = o;
    MMP.Utils.invoke_later(o->msg, packet);
}

void check_source(MMP.Packet packet, object connection, function callback, mixed ... args) {
    MMP.Uniform source;

    void cb(mapping ips) {
	if (ips && has_index(ips, connection->peerip)) {
	    call_out(callback, 0, 1, @args);
	} else {
	    call_out(callback, 0, 0, @args);
	}
    };

    if (!has_index(packet->vars, "_source")) {
	source = connection->peeraddr;
	// THIS IS REMOTE
	packet["_source"] = source;
	call_out(callback, 0, 1, @args);
	return;
    }
    
    source = packet["_source"];
    if (MMP.Utils.Net.is_ip(source->host)) {
	if (source->host == connection->peerip) {
	    call_out(callback, 0, 1, @args);
	} else {
	    call_out(callback, 0, 0, @args);
	}
    } else {
	MMP.Utils.DNS.async_srv_to_all_ip(source->host, cb);
    }
}

void check_context(MMP.Packet packet, object connection, function callback, mixed ... args) {
    MMP.Uniform context;

    void cb(mapping ips) {
	if (ips && has_index(ips, connection->peerip)) {
	    call_out(callback, 0, 1, @args);
	} else {
	    call_out(callback, 0, 0, @args);
	}
    };

    if (!has_index(packet->vars, "_context")) {
	call_out(callback, 0, 1, @args);
	return;
    }

    context = packet["_context"];
    if (MMP.Utils.Net.is_ip(context->host)) {
	if (context->host == connection->peerip) {
	    call_out(callback, 0, 1, @args);
	} else {
	    call_out(callback, 0, 0, @args);
	}
    } else {
	MMP.Utils.DNS.async_srv_to_all_ip(context->host, cb);
    }
}

void check_target(MMP.Packet packet, object connection, function callback, mixed ... args) {
    MMP.Uniform target;

    void if_cb() {
	call_out(callback, 0, 1, @args);
    };

    void else_cb() {
	call_out(callback, 0, 0, @args);
    };

    if (!has_index(packet->vars, "_target") 
    || (!MMP.is_uniform(target = packet["_target"]))) {
	call_out(callback, 0, 1, @args);
    } else {
	if_localhost(target, if_cb, else_cb);
    }
}

void check(MMP.Packet packet, object connection) {
    
    void _check(int ok, int stage) {
	if (ok) switch(stage) {
	case 0:
	    call_out(check_source, 0, packet, connection, _check, ++stage);
	    break;
	case 1:
	    call_out(check_target, 0, packet, connection, _check, ++stage);
	    break;
	case 2:
	    call_out(check_context, 0, packet, connection, _check, ++stage);
	    break;
	case 3:
	    call_out(route, 0, packet, connection);
	} else {
	    debug(([ "packet_flow" : 0, "protocol_error" : 3 ]), "Packet %O with invalid header information dropped in stage %O.\n", packet, stage);
	}
    };

    _check(1, 0);
}

void route(MMP.Packet packet, object connection) {
    
    debug("packet_flow", 5, "%O->route(%O)\n", this, packet);
    
    MMP.Uniform target, source, context;
    // this is maybe the most ... innovative piece of code on this planet
    target = packet["_target"];
    context = packet["_context"];
    source = packet["_source"];

    // may be objects already if these are packets coming from a socket that
    // has been closed.
    debug("routing", 5, "routing source: %O, target: %O, context: %O\n", 
	source, target, context);

    switch ((target ? 1 : 0)|
	    (source ? 2 : 0)|
	    (context ? 4 : 0)) {
    case 5:
    case 7:
	// unicast in context-state..
	// TODO: we dont know how to handle different states right now..
	// maybe it can be done in Uni.pmod but then we would have to 
	// double check
	
	//P0(("PSYC.Server", "unimplemented routing scheme (%d)\n", 5))
	//break;
    case 3:
    case 1:
	debug("routing", 5, "routing %O via unicast to %s\n", packet, 
	    target);

	if (target->handler) {
	    target->handler->msg(packet);
	    return;
	} 

	if (target->resource) {
	    deliver(target, packet);
	} else { // rootmsg
#ifdef DEBUG
	    void dummy(MMP.Packet p) {
		debug("routing", 0, "%O sent us a packet (%O) that apparently does not belong here.\n", p->source(), p);
	    };
#else
	    function dummy;
#endif
	    // wouldnt it be good to have if_localhost check for that
	    // in the uniform on its own?
	    //  being local should never change...
	    if (target->islocal) {
		root->msg(packet);
	    } else if (zero_type(target->islocal) == 0) {
		dummy(packet);
	    } else 
		if_localhost(target, root->msg, dummy, packet);
	}
	break;
    case 2:
    case 0:
	debug(([ "routing" : 0, "protocol_error" : 2]), "Broken Packet without _target from %O.\n", source);
	root->msg(packet);
	break;
    case 4:
	debug("routing", 2, "routing multicast message %O to local %s\n", 
	    packet, context);
	if (has_index(contexts, context)) {
	    contexts[context]->msg(packet);
	} else {
	    debug("routing", 0, "Context() empty for %O\n", 
		context);
	}
	break;
    case 6:
	debug(([ "routing" : 0, "protocol_error" : 2]), "unimplemented routing scheme (%d)\n", 6);
	// bullshit.. 
	break;
    }
}
