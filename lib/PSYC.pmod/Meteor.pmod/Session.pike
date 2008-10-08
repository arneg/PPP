inherit Serialization.BasicTypes;
inherit Serialization.PsycTypes;
inherit Serialization.Signature;

string client_id;
function cb, error;

Serialization.AtomParser parser = Serialization.AtomParser();
MMP.Utils.Queue buffer = MMP.Utils.Queue();

object connection;
object connection_request;
object new_request;
object packet;
string out_buffer;
int out_pos, write_ready;
int the_end = 0;

void muh() {
    if (!connection) return;
    PSYC.Packet p = PSYC.Packet("_message_public", ([ "_nick" : "hanswurst"+String.int2char(0x011111), "_huhu" : "flupp" ]), "you sucker!");
    send(packet->encode(p));
    call_out(muh, 2);
};

void create(string client_id, function cb, function error) {
    this_program::client_id = client_id;
    this_program::cb = cb;
    this_program::error = error;

    ::create(Serialization.TypeCache());
    packet  = PsycPacket("_message", UTF8String(), ([ "_nick" : UTF8String() ]), ([ "_huhu" : UTF8String() ]));
}

void register_new() {
    connection_request = new_request;;
    connection = new_request->my_fd;

    string headers = new_request->make_response_header(([
	"type" : "text/atom; charset=utf-8",
	"size" : -1,
	"extra_heads" : ([
	    "transfer-encoding" : "chunked",
	]),
    ]));

    connection->set_write_callback(_write);
    connection->write(headers); // fire and forget


    //remove_call_out(muh);
    call_out(muh, 2);

    new_request = 0;
    _write();
}


void handle(object request) {
    if (request->request_type == "POST") {
	if (request->body_raw == "") {
	    werror("New connection from %O.\n", request->my_fd->query_address());

	    // TODO: change internal timeout from 180 s to infinity for Request
	    new_request = request;	

	    if (connection) {
		the_end = 1;

		if (!stringp(out_buffer)) {
		    out_buffer = "0\r\n\r\n";
		    out_pos = 0;
		    if (write_ready) _write();
		} else {
		    out_buffer += "0\r\n\r\n";
		}
	    } else {
		register_new();
	    }
	} else {
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

	    request->response_and_finish(([ "data" : "ok", "type" : "text/html" ]));
	}
    } else werror("uh: %O\n", request);
}

void _write() {
    if (connection) { 
	if (!stringp(out_buffer)) {
	    if (buffer->is_empty()) {
		write_ready = 1;
		return;
	    }
	    String.Buffer s = String.Buffer();

	    while (!buffer->is_empty()) {
		Serialization.render_atom(buffer->shift(), s); 
	    }

	    out_buffer = s->get();
	    out_buffer = sprintf("%x\r\n%s\r\n", sizeof(out_buffer), out_buffer);
	    out_pos = 0;
	}
	    
	werror("writing to %O\n", connection->query_address());
	out_pos += connection->write(out_buffer);

	if (connection->errno()) {
	    connection_request->finish(0);
	    connection  = 0;
	    connection_request = 0;
	    werror("connection error.\n");
	} else if (out_pos == sizeof(out_buffer)) {
	    out_buffer = 0;
	    out_pos = 0;

	    if (the_end) {
		connection_request->finish(1);
		the_end = 0;
		register_new();
	    }
	}

	write_ready = 0;
    }
}

void send(Serialization.Atom atom) {
    buffer->push(atom);
    werror("sending %O\n", atom);

    if (write_ready) {
	_write();
    }
}
