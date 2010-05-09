//! This is an intermediate object which tries to keep a @[Circuit] to a certain
//! target open. Multiple of this adapters may share the same @[Circuit].
//! However, if a @[Circuit] breaks and can't be reestablished, adapters that 
//! once shared a @[Circuit] may end up in using different ones (potentially 
//! to different servers).
//! 
//! Supports SRV records in domain resolution.

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
