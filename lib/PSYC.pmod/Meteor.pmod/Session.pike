inherit Serialization.BasicTypes;
inherit Serialization.PsycTypes;
inherit Serialization.Signature;

string client_id;
function cb, error;

Serialization.AtomParser parser = Serialization.AtomParser();
MMP.Utils.Queue buffer = MMP.Utils.Queue();

object connection;
object connection_request;
object packet;

void create(string client_id, function cb, function error) {
    this_program::client_id = client_id;
    this_program::cb = cb;
    this_program::error = error;

    ::create(Serialization.TypeCache());
    packet  = PsycPacket("_message", UTF8String(), ([ "_nick" : UTF8String() ]), ([ "_huhu" : UTF8String() ]));
}


void handle(object request) {
    if (request->request_type == "POST") {
	parser->feed(request->body_raw);

	Serialization.Atom a;
	mixed err = catch {
	    while (a = parser->parse()) {
		call_out(cb, 0, this, a);
	    }
	};

	if (err) { // this is reason to disconnect
	    error(err);
	}

	if (!connection) {
	    connection_request = request;
	    connection = request->my_fd;

	    string headers = request->make_response_header(([
		"type" : "text/atom",
		"size" : -1,
	    ]));

	    connection->write(headers);


	    void muh() {
		if (!connection) return;
		PSYC.Packet p = PSYC.Packet("_message_public", ([ "_nick" : "hanswurst\454", "_huhu" : "flupp" ]), "you sucker!");
		send(packet->encode(p));
		call_out(muh, 3);
	    };

	    call_out(muh, 2);

	    if (!buffer->is_empty()) {
		_write();
	    }
	} else {
	    request->response_and_finish(([ "data" : "ok", "type" : "text/html" ]));
	}

    } else werror("uh: %O\n", request);
}

void _write() {
    if (connection && !buffer->is_empty()) {
	String.Buffer s = String.Buffer();

	while (!buffer->is_empty()) {
	    Serialization.render_atom(buffer->shift(), s); 
	}
	
	connection->write(s->get());
	if (connection->errno()) {
	    connection  = 0;
	    connection_request = 0;
	}
    }
}

void send(Serialization.Atom atom) {
    buffer->push(atom);
    werror("sending %O\n", atom);

    if (connection) {
	_write();
    }
}
