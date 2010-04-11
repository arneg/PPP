inherit MMP.Utils.UniformCache;

MMP.Circuit out;
string bind_local;

mapping(string:MMP.Circuit) circuit_cache = set_weak_flag(([ ]), Pike.WEAK_VALUES);
mapping(string:MMP.VirtualCircuit) vcircuit_cache = ([]);

void circuit_to(string host, int port, function(MMP.Circuit:void) cb) {
    if (!port) port = .DEFAULT_PORT;
    string hip = sprintf("%s:%d", host, port);
    MMP.Circuit t;

    if (t = circuit_cache[hip]) {
	call_out(cb, 0, t);
	return;
    }

    Stdio.File f = Stdio.File();
    if (bind_local) f->open_socket(UNDEFINED, bind_local);

    void connected(int success) {
	if (!success) werror("Could not connect to host %s\n", hip);
	else cb(MMP.Circuit(f, msg, close, this));
    };
    
    f->async_connect(host, port, connected);
}

void register_entity(MMP.Uniform u, object o) {
}

object get_entity(MMP.Uniform u) {
    return 0;
}

void msg(MMP.Packet p, object c) {
    werror("got: %O from %O\n", p, c);
}

void close(mixed ... args) {
    werror("%O was closed.\n", args);
}

void verror_cb(mixed ... args) {
    werror("vcircuit error: %O\n", args);
}

void accept(mixed id) {
    Stdio.File f = id->accept();
    MMP.Circuit c = MMP.Circuit(f, msg, close, this);
    string host = f->query_address();
    string hip;
    int port;

    if (stringp(host)) sscanf(host, "%s %d", host, port);
    else error("Some error occured after accept of %O: %s\n", f, strerror(f->errno()));

    hip = sprintf("%s:-%d", host, port);

    if (has_index(circuit_cache, hip)) {
	werror("An old Vcircuit existed %O. cleaning up.\n", circuit_cache[hip]);
    }

    vcircuit_cache[hip] = MMP.VirtualCircuit(get_uniform("psyc://"+hip+"/"), this, verror_cb, 0, c);
}

void bind(void|string ip, void|int port) {
    Stdio.Port p = Stdio.Port(port, accept, ip);
    p->set_id(p);
}

MMP.Circuit get_route(MMP.Uniform target) {
}

void create(mapping settings) {
    
    if (intp(settings->bind) || stringp(settings->bind)) {
	settings->bind = ({ settings->bind });
    }

    foreach (settings->bind;; string|int t) {
	if (intp(t)) bind(0, t);
	else if (stringp(t)) {
	    string host;
	    int port;

	    sscanf(t, "%[^:]:%d", host, port);
	    if (host && !bind_local) bind_local = host;
	    bind(host, port);
	} else error("Cannot bind to this: %O\n", t);

    }

    if (settings->entitites) foreach(settings->entities; mixed uni; object o) {
	if (stringp(uni)) {
	    MMP.Uniform t;

	    if (t = get_uniform(uni)) {
		register_entity(t, o);
	    } else {
		werror("'%s' is not a valid Uniform.\n");
	    }
	} else {
	    register_entity(stringp(uni) ? get_uniform(uni) : uni, o);
	}
    }
}
