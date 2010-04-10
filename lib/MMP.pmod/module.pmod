// vim:syntax=lpc

//! Implementation of MMP Circuits as described nowhere really.
class Circuit {
    inherit MMP.Utils.Queue;

    //! The socket used.
    Stdio.File|Stdio.FILE socket;

    MMP.Utils.Queue q_neg = MMP.Utils.Queue();
    int write_ready, write_okay; // sending may be forbidden during
				 // certain parts of neg

    int pcount = 0;

    //! @[MMP.Uniform] associated with this connection. @expr{localaddr@} and
    //! and @expr{remoteaddr@} include the port, they are therefore not 
    //! necessarily equal to the adresses of the two @[PSYC.Root] objects.
    MMP.Uniform peeraddr, localaddr;

    //! Ip adress of the local- and peerhost of the tcp connection used.
    string peerip, localip;

    function close_cb, get_uniform;
    mapping(function:array) close_cbs = ([ ]); // close_cb == server, close_cbs
					       // contains the callbacks of
					       // the VCs.

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
    void create(Stdio.File|Stdio.FILE socket, function cb, function close_cb,
		void|function parse_uni) {
	P2(("MMP.Circuit", "create(%O, %O, %O)\n", so, cb, closecb))
	this_program::socket = socket;
	socket->set_nonblocking(start_read, write, close);
	this_program::close_cb = close_cb;
	get_uniform = parse_uni||MMP.parse_uniform;

	localip = (socket->query_address(1) / " ")[0];
	peerip = (socket->query_address() / " ")[0];

	q_neg->push(Packet());

	void msg_cb(MMP.Packet p) {
	    P2(("MMP.Circuit", "parsed %O.\n", p))
	    if (p->data) {
		// TODO: HOOK
		if (p->parsed)
		    p->parsed();
		if (objectp(p["_target"])) {

		    if (pcount < 3) {
			if (!p["_target"]->reconnectable) p["_target"]->islocal = 1;
		    }

		}
	    } else {
		P2(("MMP.Circuit", "Got a ping.\n"))
	    }

	    cb(p, this); 
	    pcount++;
	};

	mixed transform(string key, mixed value) {

	    // TODO: has_prefix is not quite right...
	    if (stringp(value)) {
		if (has_prefix(key, "_source") 
		||  has_prefix(key, "_target")
		||  has_prefix(key, "_context"))
		    return get_uniform(value);
	    }

	    return value;
	};

	parser = MMP.Parser(([ "callback" : msg_cb, "transform" : transform ]));
	//::create();
    }

    string _sprintf(int type) {
	switch (type) {
	case 's':
	case 'O':
	    return sprintf("MMP.Circuit(%O)", peeraddr);
	}
    }

    //! Start actually sending packets.
    //! @note
    //!	    This will be called for you by @[Server].
    void activate() {
	P3(("MMP.Circuit", "%O->activate()\n", this))
	write_okay = 1;
	if (write_ready) write();
    }

    //! Send a negotiation packet. @expr{packet@} will be send even
    //! if the @[Circuit] has not been activated using @[activate()].
    //! @note
    //!	    Use this with care and for negotiation only!
    void send_neg(Packet packet) {
	P3(("MMP.Circuit", "%O->send_neg(%O)\n", this, packet))
	q_neg->push(packet);

	if (write_ready) {
	    write();
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
    void msg(MMP.Utils.Queue holder) {
	P3(("MMP.Circuit", "%O->msg(%O)\n", this, holder))
	P3(("MMP.Circuit", "%O->msg(%O) where write_ok: %O, write_ready: %O\n", this, sizeof(holder), write_okay, write_ready))
	push(holder);

	if (write_ready) {
	    write();
	}
    }

    int write(void|mixed id) {
	MMP.Utils.Queue currentQ, realQ;
	// we could go for speed with
	// function currentshift, currentunshift;
	// as we'd only have to do the -> lookup for q_neg packages then ,)
	
	if (!write_okay) return (write_ready = 1, 0);

	if (!q_neg->isEmpty()) {
	    currentQ = q_neg;
	    P2(("MMP.Circuit", "Negotiation stuff..\n"))
	} else if (!isEmpty()) {
	    currentQ = this;
	    P2(("MMP.Circuit", "Normal queue...\n"))
	} 
#if DEBUG
	else {
	    P2(("MMP.Circuit", "No packets in queue.\n"))
	}
#endif

	realQ = currentQ;

	if (!currentQ) {
	    write_ready = 1;
	} else {
	    int written;
	    mixed tmp;
	    string s;

	    write_ready = 0;

	    if (currentQ == this) realQ = shift();

	    tmp = realQ->shift();

	    if (arrayp(tmp)) {
		[s, tmp] = tmp;
		// it seems more logical to me, to put all this logic into
		// close.
		if (tmp) (realQ = shift())->shift();
	    } else /* if (objectp(tmp)) */ {
		s = tmp->next();
		if (tmp->has_next()) {
		    realQ->push(tmp);
		    realQ = 0;
		}
		// TODO: HOOK
	    }

	    // TODO: encode
	    //s = trigger("encode", s);
	    written = socket->write(s);

	    P2(("MMP.Circuit", "%O wrote (%O) %d (of %d) bytes.\n", this, s, written, 
		sizeof(s)))

	    if (written != sizeof(s)) {
		if (realQ) {
		    q_neg->unshift(({ s[written..], tmp }));
		    unshift(realQ);
		    realQ->unshift(tmp);	
		} else {
		    q_neg->unshift(({ s[written..], 0 }));
		}
	    } else {
		if (tmp->sent)
		    tmp->sent();
	    }
	}

	return 1;
    }

    int start_read(mixed id, string data) {

	// is there anyone who would send \n\r ???
	if (data[0 .. 1] != ".\n") {
	    // TODO: error message
	    socket->close();
	    close(0);
	    return 1;
	}

	// the reset has been called before.
	P2(("MMP.Circuit", "%s sent a proper initialisation packet.\n", 
	    peeraddr))
	if (sizeof(data) > 2) {
	    read(0, data[2 ..]);
	}

	socket->set_read_callback(read);
    }

    int read(mixed id, string data) {
	// TODO: decode

	P2(("MMP.Circuit", "read %d bytes.\n", sizeof(data)))

	array(mixed) exception = catch {
	    parser->parse(data);
	};

	if (exception) {
	    if (objectp(exception)
		&& Program.inherits(object_program(exception), Error.Generic)) {
		P0(("MMP.Circuit", "Caught an error: %O, %O\n", exception,
		    exception->backtrace()))
	    } else {
		P0(("MMP.Circuit", "Caught an error: %O\n", exception))
	    }
	    // TODO: error message
	    socket->close();
	    close(0);
	}


	return 1;	
    }

    int close(mixed id) {
	P0(("MMP.Circuit", "%O: Connection closed.\n", this))
	// TODO: error message
	close_cb(this);

	foreach (close_cbs; function cb; array args) {
	    cb(@args);
	}
    }

    void add_close_cb(function cb, mixed ... args) {
	close_cbs[cb] = args;
    }

    void remove_close_cb(function cb) {
	m_delete(close_cbs, cb);
    }
}

//! A @[Circuit] that is active (i.e. an outgoing connection).
class Active {
    inherit Circuit;

    void create(Stdio.File|Stdio.FILE so, function cb, function closecb, void|function get_uniform) {

	void _cb(MMP.Packet p, object c) {
	    if (!p->data) {
		// drop pings..
		return;
	    }

	    cb(p, c);
	};

	::create(so, _cb, closecb, get_uniform);

	string peerhost = so->query_address(1);
	localaddr = get_uniform("psyc://"+((peerhost / " ") * ":-"));
	localaddr->islocal = 1;
	peerhost = so->query_address();
	peeraddr = get_uniform("psyc://"+((peerhost / " ") * ":"));
	peeraddr->islocal = 0;
	//peeraddr->handler = this;
    }
}

//! A @[Circuit] that is passive (i.e. an inbound connection). Use this for 
//! already @[Stdio.Port()->accept()]ed sockets (sockets ready to transport
//! MMP).
class Server {
    inherit Circuit;

    void create(Stdio.File|Stdio.FILE so, function cb, function closecb, void|function get_uniform) {
	
	void _cb(MMP.Packet p, object c) {
	    if (!p->data) {
		send_neg(Packet());
		return;
	    }

	    cb(p, c);
	};

	::create(so, _cb, closecb, get_uniform);

	string peerhost = so->query_address(1);
	localaddr = get_uniform("psyc://"+((peerhost / " ") * ":"));
	localaddr->islocal = 1;
	peerhost = so->query_address();
	peeraddr = get_uniform("psyc://"+((peerhost / " ") * ":-"));
	peeraddr->islocal = 0;

	activate();
    }

    int sgn() {
	return -1;
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
	P2(("VirtualCircuit", "create(%O, %O, %O)\n", _peer, srv, c))

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
	if (MMP.Utils.Net.is_ip(targethost) && !port) port = 4404;

	if (port) {
	    connect_host(targethost, port);
	} else {
	    connect_srv();
	}
    }

    void on_close() {
	circuit = 0;
	init();
    }

    void on_connect(MMP.Circuit c) {
	if (c) {
	    int sof = _sizeof();
	    circuit = c;
	    destruct(cres);

	    // so we will get notified when the connection can't be
	    // maintained any longer (connection break, reconnect fails)
	    circuit->add_close_cb(on_close);

	    for (int i = 0; i < sof; i++) {
		circuit->msg(this);
	    }
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
	server->circuit_to(peer, on_connect);
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

    void destroy() { // just in case... dunno when the maintenance in here
		     // is neccessary. probably never, but doesn't hurt much.
	circuit->remove_close_cb(on_close);
    }

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
	    P3(("VirtualCircuit", "srvcb(%O, %O)\n", query, result))
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
		    connect_host(targethost, 4404);
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
	P2(("VirtualCircuit", "%O->msg(%O)\n", peer, p))
	if (dead) {
	    failure_delivery(p["_target"] || peer, p);
	    return;
	}
	push(p);

	if (circuit) circuit->msg(this);
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

