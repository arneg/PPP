// vim:syntax=lpc
object server;
multiset(MMP.Uniform) members = (<>);
mapping(MMP.Uniform:int) routes = ([]);
mapping options;
int count = 0;

// TODO: 
// - doesnt know who he is and therefore needs to know the route to the
//   context
// - think about the local checks.

void create(object s) {
    server = s;
}

void insert(MMP.Uniform u) {

    if (u->is_local()) {
	members[u] = 1;
	routes[u] = 1;
    } else {
	members[u] = 1;
	routes[u->root]++;
    }

}

int contains(MMP.Uniform u) {
    return has_index(members, u);
}

void remove(MMP.Uniform u) {

    while (members[u]--);
    if (u->is_local()) {
	m_delete(routes, u);
	return;
    } else {
	if (has_index(routes, u->root)) {
	    if (routes[u->root] == 1) {
		m_delete(routes, u->root);
	    }
	}
    }

}

int _sizeof() {
    return sizeof(members);
}

void msg(MMP.Packet p) {
    p["_counter"] = count++;

    // the PSYC packet actually goes through unparsed. and it is parsed once if
    // its delivered locally. hooray
    foreach(routes; MMP.Uniform u;) {
	server->deliver(u, p);
    }
}