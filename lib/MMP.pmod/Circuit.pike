//! Implementation of MMP Circuits as described nowhere really.

inherit MMP.Utils.Queue;
inherit Serialization.Signature;
inherit MMP.MmpTypes;
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
	socket->set_read_callback(0);
	socket->set_close_callback(0);
	socket->close();
	socket = 0;
	server = 0;
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
