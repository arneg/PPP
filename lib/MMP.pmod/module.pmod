// vim:syntax=lpc

constant DEFAULT_PORT = 4044;

//! Implementation of MMP Circuits as described nowhere really.
class Circuit {
    inherit MMP.Utils.Queue;
    inherit Serialization.Signature;
    inherit PSYC.PsycTypes;
    inherit MMP.Utils.Debug;

    //! The socket used.
    MMP.Utils.BufferedStream socket = MMP.Utils.BufferedStream();
    MMP.Types.Packet mmp_signature;
    Serialization.AtomParser parser = Serialization.AtomParser();

    //! @[MMP.Uniform] associated with this connection. @expr{localaddr@} and
    //! and @expr{remoteaddr@} include the port, they are therefore not 
    //! necessarily equal to the adresses of the two @[PSYC.Root] objects.
    MMP.Uniform peeraddr, localaddr;

    //! Ip adress of the local- and peerhost of the tcp connection used.
    string hip, lhip;

    function cb;
    object server;
    mapping(function:array) close_cbs = ([ ]); 

    // cb(received & parsed mmp_message);
    //
    // on close/error:
    // closecb(0); if connections gets closed,
    // 	 --> DISCUSS: closecb(string logmessage); on error? <--
    // 	 maybe: closecb(object dings, void|string error)
    //! @param socket
    //!	    Socket to use. 
    //! @param cb
    //!	    Callback to call for incoming @[MMP.Packet]s. Expected signature is:
    //!	    @expr{void cb(MMP.Packet packet, MMP.Circuit connection);@}
    //! @param close_cb
    //!	    Callback to be called when the @expr{so@} is being closed.
    //!	    Expected signature is: 
    //!	    @expr{void cb(MMP.Circuit connection);@}
    //! @param parse_uni
    //!	    Function to use to parse Uniforms. This is used in @[PSYC.Server] to
    //!	    keep the Uniform cache consistent.
    void create(Stdio.File|Stdio.FILE socket, function cb, object server, int(0..1) inbound) {
	P2("MMP.Circuit", "create(%O, %O, %O)\n", socket, cb);

	if (!socket->is_open()) error("Socket %O is not open. This should not happen!\n", socket);

	this_program::socket->assign(socket);
	this_program::cb = cb;
	this_program::server = server;

	socket->set_read_callback(read);
	socket->set_close_callback(on_close);

	mmp_signature = Packet(Atom());

	hip = socket->query_address();
	lhip = socket->query_address(1);

	if (!stringp(hip) || !stringp(lhip)) error("Socket %O is broken: %s\n", socket, strerror(socket->errno()));

	if (inbound) {
	    hip = replace(hip, " ", ":-");
	    lhip = replace(hip, " ", ":");
	} else {
	    hip = replace(hip, " ", ":");
	    lhip = replace(hip, " ", ":-");
	}
    }

    string _sprintf(int type) {
	switch (type) {
	case 's':
	case 'O':
	    string s = (socket && socket->is_open()) ? socket->query_address() : "closed";
	    if (!stringp(s)) s = sprintf("error: %s (was: %s)", strerror(socket->errno()), hip);
	    return sprintf("MMP.Circuit(%s)", s);
	}
    }

    //! Register a packet for sending.
    //! @param holder
    //!	    A @[MMP.Utils.Queue] which holds the @[MMP.Packet] to be sent.
    //! @note
    //!	    Better do @b{not use this directly@}, but use a @[VirtualCircuit]
    //!	    (or something similar you build) to send packets.
    //! @seealso
    //!	    Remember to @[activate()] the Circuit, otherwise no packet
    //!	    will be sent.
    void send(MMP.Packet p) {
	P3("MMP.Circuit", "%O->send(%O)\n", this, p);
	
	socket->write(mmp_signature->render(p)->get());
    }

    int read(mixed id, string data) {
	P2("MMP.Circuit", "read %d bytes.\n", sizeof(data));

	array(mixed) exception = catch {
	    parser->feed(data);

	    while (Serialization.Atom atom = parser->parse()) {
		call_out(cb, 0, mmp_signature->decode(atom), this);
	    }
	};

	if (exception) {
	    werror("EXCEPTION: %O\n", exception);
	    if (objectp(exception)
		&& Program.inherits(object_program(exception), Error.Generic)) {
		P0("MMP.Circuit", "Caught an error: %O, %O\n", exception, exception->backtrace());
	    } else {
		P0("MMP.Circuit", "Caught an error: %O\n", exception);
	    }
	    // TODO: error message
	    socket->close();
	    on_close(0);
	}

	return 1;	
    }

    void close() {
	werror("closing %O not implemented.\n", this);
    }

    int on_close(mixed id) {
	P0("MMP.Circuit", "%O: Connection closed.\n", this);
	// TODO: error message
	foreach (close_cbs; function cb; array args) {
	    mixed err = catch { cb(this, @args); };
	    if (err) werror("Close callback %O threw an exception: %O\n", cb, describe_error(err));
	}

	close_cbs = 0;
	cb = 0;
	socket->set_read_callback(0);
	socket->set_close_callback(0);
	socket = 0;
	server = 0;
	mmp_signature = 0;
    }

    void add_close_cb(function cb, mixed ... args) {
	close_cbs[cb] = args;
    }

    void remove_close_cb(function cb) {
	m_delete(close_cbs, cb);
    }
}

//! This is an intermediate object which tries to keep a @[Circuit] to a certain
//! target open. Multiple of this adapters may share the same @[Circuit].
//! However, if a @[Circuit] breaks and can't be reestablished, adapters that 
//! once shared a @[Circuit] may end up in using different ones (potentially 
//! to different servers).
//! 
//! Supports SRV records in domain resolution.
class VirtualCircuit {
    inherit MMP.Utils.Queue; // me hulk! me can queue!
    inherit MMP.Utils.Debug;

    MMP.Circuit circuit;
    MMP.Utils.DNS.SRVReply cres;
    object server; // duh. pike really needs a way to solve "recursive"
		   // dependencies.
    function check_out, failure_delivery;
    // following two will be needed when a circuit breaks and can't be
    // reestablished
    string targethost;
    int targetport, dead = 0;
    MMP.Uniform peer;

    string _sprinf(int type) {
	if (type == 's' || type == 'O') {
	    return sprintf("MMP.VirtualCircuit(%s:%d)", targethost, targetport);
	}
    }

    //! @param peer
    //!	    Uniform of the peer to connect to. If the port is omitted service 
    //!	    discovery is done using SRV Records.
    //! @param server
    //!	    @[PSYC.Server] or similar object, which offers
    //!	    @ul
    //!		@item
    //!		    @expr{void connect_to(MMP.Uniform to_root, function(MMP.Circuit : void) cb);@}
    //!		@item
    //!		    @expr{MMP.Uniform get_uniform(string uniform);@}
    //!
    //!		    (See @[PSYC.Server()->get_uniform()]).
    //!	    @endul
    //! @param error
    //!     Callback to be called for packets that could not be delivered successfully.
    //! @param check_out
    //!	    A callback the @[VirtualCircuit] calls to check out from the server.
    //!	    Currently unused.
    //! @param c
    //!	    If a suiting @[Circuit] should be at hand, pass this as @expr{c@}.
    //!	    No resolving and/or connection action will then be taken until @expr{c@}
    //!	    "breaks".
    void create(MMP.Uniform peer, object server, function|void error, 
		function|void check_out, MMP.Circuit|void c) {
	P2("VirtualCircuit", "create(%O, %O, %O)\n", peer, server, c);

	this_program::peer = peer;
	targethost = peer->host;
	targetport = peer->port;

	this_program::server = server;
	this_program::check_out = check_out;
	failure_delivery = error;

	if (!c) {
	    init();
	} else {
	    on_connect(c);
	}
    }

    void init() {
	int port = targetport;
	if (MMP.Utils.Net.is_ip(targethost) && !port) port = DEFAULT_PORT;

	if (port) {
	    connect_host(targethost, port);
	} else {
	    connect_srv();
	}
    }

    void say_goodbye() {
	server = 0;
	peer = 0;
	failure_delivery = 0;
	if (check_out) {
	    check_out();
	    check_out = 0;
	} else error("And I never checked out from Outlook Hotel.\n");
    }

    void on_close(MMP.Circuit c) {
	circuit->remove_close_cb(on_close);
	circuit = 0;
	
	if (!peer->reconnectable) {
	    say_goodbye();
	    return;
	}

	init();
    }

    void on_connect(MMP.Circuit|int c) {
	if (objectp(c)) {
	    circuit = c;
	    destruct(cres);

	    // so we will get notified when the connection can't be
	    // maintained any longer (connection break, reconnect fails)
	    werror("circ: %O\n", circuit);
	    circuit->add_close_cb(on_close);

	    for (;!is_empty();) {
		circuit->send(shift());
	    }
	} else if (c == 1) {
	    // empty queue?
	    say_goodbye();
	} else {
	    if (cres) {
		srv_step();
	    } else {
		error_unroll();
		// this error is here to catch the port < 0 case.

		// TODO:: try alternatives (srv, multiple a rr), eventually
		// error. move error_unroll to the end.
	    }
	}
    }

    void connect_ip(string ip, int port) {
	server->circuit_to(ip, port, on_connect);
    }

    void connect_host(string host, int port) {
	void dispatch(string query, string ip) {
	    if (ip) {
		connect_ip(ip, port);
	    } else {
		// TODO:: error
		error_unroll();
	    }
	};

	if (MMP.Utils.Net.is_ip(host)) {
	    connect_ip(host, port);
	} else {
	    // TODO:: resolve in a way that gives us multiple records.
	    Protocols.DNS.async_host_to_ip(host, dispatch);
	}
    }

#if 0
    void destroy() { // just in case... dunno when the maintenance in here
		     // is neccessary. probably never, but doesn't hurt much.
	if (circuit) circuit->remove_close_cb(on_close);
    }
#endif

    void srv_step() {
	if (cres->has_next()) {
	    mapping m = cres->next();

	    connect_host(m->target, m->port);
	} else {
	    destruct(cres);

	    error_unroll();
	    // TODO:: there was at least one srv-host, not reachable, so we
	    // can't reach the target and therefore need to error!
	}
    }

    void connect_srv() {
	void srvcb(string query, MMP.Utils.DNS.SRVReply|int result) {
	    P3("VirtualCircuit", "srvcb(%O, %O)\n", query, result);
	    if (objectp(result)) {
		if (result->has_next()) {
		    if (has_value(result->result->target, ".")) {
			// no psyc offered. error all queued packages, error
			// and destruct.
		    } else {
			cres = result;
			srv_step();
		    }
		} else {
		    connect_host(targethost, MMP.DEFAULT_PORT);
		}
	    }
	};

	MMP.Utils.DNS.async_srv("psyc-server", "tcp", targethost, srvcb);
    }

    void error_unroll() {
	dead = 1;
	while (sizeof(this)) {
	    MMP.Packet p = shift();

	    failure_delivery(p["_target"] || peer, p);
	}
    }

    //! Sends a @[Packet] to this @[VirtualCircuit]'s target.
    //! If delivery fails, eventually opening new circuits to other
    //! (responsible) servers will be opened.
    void msg(MMP.Packet p) {
	P2("VirtualCircuit", "%O->msg(%O)\n", peer, p);
	if (dead) {
	    failure_delivery(p["_target"] || peer, p);
	    return;
	}

	if (circuit) circuit->send(p);
	else push(p);
    }

    void close() {
	// TODO
	werror("close %O not implemented.\n", this);
    }
}

//! @returns
//!	@int
//!	    @value 0
//!		@expr{var@} is not an MMP variable.
//!	    @value 1
//!		@expr{var@} is an MMP variable that should be seen
//!		by the application layer.
//!	    @value 2
//!		@expr{var@} is an MMP variable that should be used
//!		by the routing layer of your program only.
//!	@endint
//! @seealso
//!	For a description of MMP variables see @[http://psyc.pages.de/mmp.html].
int(0..2) is_mmpvar(string var) {
    switch (var) {
    case "_target":
    case "_target_relay":
    case "_source":
    case "_source_relay":
    case "_source_location":
    case "_source_identification":
    case "_context":
    case "_length":
    case "_counter":
    case "_reply":
    case "_trace":
    case "_amount_fragments":
    case "_fragment":
		return 1;
    case "_encoding":
    case "_list_require_modules":
    case "_list_require_encoding":
    case "_list_require_protocols":
    case "_list_using_protocols":
    case "_list_using_modules":
    case "_list_understand_protocols":
    case "_list_understand_modules":
    case "_list_understand_encoding":
		return 2;
    }

    return 0;
}


//! @returns
//! @int
//! 	@value 1
//! 		@expr{o@} is a @[Uniform].
//! 	@value 0
//! 		@expr{o@} is not a @[Uniform].
//! @endint
int(0..1) is_uniform(mixed o) {
    if (objectp(o) && Program.inherits(object_program(o), MMP.Uniform)) {
	return 1;
    } else {
	return 0;
    }
}

//! @returns
//! @int
//! 	@value 1
//! 		@expr{o@} is a MMP.Uniform designated by @expr{designator@}
//! 	@value 0
//! 		@expr{o@} is not a Person.
//! @endint
//!
//! @seealso
//!	@[is_person()], @[is_place()], @[is_uniform()]
int(0..1) is_thing(mixed o, int designator) {
    return is_uniform(o) && stringp(o->resource) && sizeof(o->resource) && o->resource[0] == designator;
}

//! @returns
//! @int
//! 	@value 1
//! 		@expr{o@} is a Person (designated by an '~' in MMP/PSYC).
//! 	@value 0
//! 		@expr{o@} is not a Person.
//! @endint
//!
//! @seealso
//!	@[is_thing()], @[is_place()], @[is_uniform()]
int(0..1) is_person(mixed o) {
    return is_thing(o, '~');
}

//! @returns
//! @int
//! 	@value 1
//! 		@expr{o@} is a Place (designated by an '@@' in MMP/PSYC).
//! 	@value 0
//! 		@expr{o@} is not a Place.
//! @endint
//! @seealso
//!	@[is_thing()], @[is_person()], @[is_uniform()]
int(0..1) is_place(mixed o) {
    return is_thing(o, '@');
}


array(string) abbreviations(string m) {
	array(string) a = m / "_";

	if (sizeof(a[0]) && sizeof(a) < 2) error("Invalid method: %O\n", m);

	for (int i = 1; i < sizeof(a); i++) a[i] = a[i-1] + "_" + a[i];

	return a;
}
