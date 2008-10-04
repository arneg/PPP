string client_id;
function cb, error;

Serialization.AtomParser parser = Serialization.AtomParser();
MMP.Utils.Queue requests = MMP.Utils.Queue();
MMP.Utils.Queue buffer = MMP.Utils.Queue();

void create(string client_id, function cb, function error) {
    this_program::client_id = client_id;
    this_program::cb = cb;
    this_program::error = error;
}

void handle(object request) {
    if (request->request_type == "POST") {
	requests->push(request);	
	parser->feed(request->body_raw);

	Serialization.Atom a;
	mixed err = catch {
	    while (a = parser->parse()) {
		call_out(cb, 0, a);
	    }
	};

	if (err) { // this is reason to disconnect
	    error(err);
	}

	if (!buffer->is_empty()) {
	    _write();
	}
    } else werror("uh: %O\n", request);
}

void _write() {
    if (!requests->is_empty() && !buffer->is_empty()) {
	String.Buffer s = String.Buffer();

	while (!buffer->is_empty()) {
	    Serialization.render_atom(buffer->shift(), s); 
	}

	object request = requests->shift();

	request->resonse_and_finish(([
	    "data" : s->get(), 
	    "type" : "text/atom",
	]));
    }
}

void send(Serialization.Atom atom) {
    buffer->push(atom);

    if (!requests->is_empty()) {
	_write();
    }
}
