object server;
multiset(MMP.Uniform) members = (<>);
mapping(MMP.Uniform:int) routes = ([]);

void create(object s) {
    server = s;
}

void insert(MMP.Uniform u, function cb, mixed ... args) {
    void callback(MMP.Packet p, array(mixed) args) {
	PSYC.Packet m = p->data;

	if (search(m->mc, "_status_context_enter") != -1) {

	    members[u] = 1;
	    routes[u->root]++;

	    cb(0, @args);
	} else {
	    cb(1, @args);
	}
    };

    server->root->send_tagged(u->root, PSYC.Packet("_request_context_enter"), callback, args);
}

void remove(MMP.Uniform u, function cb, mixed ... args) {
    void callback(MMP.Packet p, array(mixed) args) {
	PSYC.Packet m = p->data;

	// maybe we should not even ask in case of the leave.. but what can we do??
	if (search(m->mc, "_status_context_leave") != -1) {
	    members[u] = 0;

	    if (has_index(routes, u->root)) {
		if (routes[u->root] == 1) {
		    m_delete(routes, u->root);
		}
	    }

	    cb(0, @args);
	} else {
	    cb(1, @args);
	}
    };

    server->root->send_tagged(u->root, PSYC.Packet("_request_context_leave"), callback, args);
}

int _sizeof() {
    return sizeof(members);
}

void msg(MMP.Packet p) {
    foreach(routes; MMP.Uniform u;) {
	server->deliver(u, p);
    }
}
