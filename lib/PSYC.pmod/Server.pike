    mapping(string:mixed) localhosts;
    mapping(string:object)  
			   connecting = ([ ]), // pending, unusable connections
			   connections = ([ ]),// up and running connections
			   routes = ([ ]);     // connections routing for for
					       // somebody else
    mapping(MMP.Uniform:object) contexts = ([ ]);
    mapping(string:MMP.Uniform) unlcache = ([ ]);
    PSYC.Packet circuit_established;
    string bind_to;
    string def_localhost;
    PSYC.Root root;

    function create_local, create_remote, external_deliver_remote, external_deliver_local;

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
    void register_context(MMP.Uniform c, object o) {
	if (has_index(contexts, c)) throw(({"murks"}));
	contexts[c] = o;
    }

    void unregister_context(MMP.Uniform c) {
	m_delete(contexts, c);
    }

    object get_context(MMP.Uniform c) {
	return contexts[c];
    }

    void add_route(MMP.Uniform target, object connection) {
	routes[target->host + " " + (string)(target->port||4404)] = connection;
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
	MMP.Uniform t = get_uniform("psyc://" + def_localhost + "/");
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

	connections[peerhost] = (con = MMP.Server(socket, route, close, get_uniform));
	con->send_neg(MMP.Packet(circuit_established, ([ "_source" : root->uni, "_target" : con->peeraddr ])) );
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
	    return unlcache[unl] = MMP.Uniform(unl);
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
	    call_out((target->handler = connections[peerhost])->msg, 0, packet);
	    return;
	} else if (has_index(routes, peerhost)) {
	    call_out((target->handler = routes[peerhost])->msg, 0, packet);
	    return;
	}

	if (sscanf(host, "%*d.%*d.%*d.%*d") != 4) {
	    P0(("PSYC.Server", "uarg, %O\n", host))
	    Protocols.DNS.async_host_to_ip(host, cb, port, packet);

	    return;
	}

	call_out(cb, 0, host, host, port, packet);
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
