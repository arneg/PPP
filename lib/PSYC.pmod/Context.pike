// vim:syntax=lpc
object server;
multiset(MMP.Uniform) members = (<>);
mapping(MMP.Uniform:int) routes = ([]);
mapping options;

void create(object s) {
    server = s;
}

void insert(MMP.Uniform u, function cb, mixed ... args) {

    if (u->is_local()) {
	members[u] = 1;
	routes[u] = 1;

	call_out(cb, 0, @args);
	return;
    }

    void callback(MMP.Packet p, array(mixed) args) {
	PSYC.Packet m = p->data;

	if (search(m->mc, "_status_context_enter") != -1) {

	    members[u] = 1;
	    routes[u->root]++;

	    call_out(cb, 0, @args);
	} else {
	    call_out(cb, 1, @args);
	}
    };

    server->root->send_tagged(u->root, PSYC.Packet("_request_context_enter"), callback, args);

}

void remove(MMP.Uniform u, function cb, mixed ... args) {

    if (u->is_local()) {
	members[u] = 0;
	m_delete(routes, u);

	call_out(cb, 0, @args);
	return;
    }

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

	    call_out(cb, 0, @args);
	} else {
	    call_out(cb, 1, @args);
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
