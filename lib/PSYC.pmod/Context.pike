// vim:syntax=lpc
object server;
multiset(MMP.Uniform) members = (<>);
mapping(MMP.Uniform:int) routes = ([]);
mapping options;
int count = 0;

#include <debug.h>

// TODO: 
// - doesnt know who he is and therefore needs to know the route to the
//   context
// - think about the local checks.

void create(object s) {
    server = s;
}

void insert(MMP.Uniform u, function cb, mixed ... args) {
    P3(("PSYC.Context", "insert(%O).\n", u))

    if (u->is_local()) {
	members[u] = 1;
	routes[u] = 1;
    } else {
	members[u] = 1;
	routes[u->root]++;
    }

    call_out(cb, 0, 0, @args);
}

int contains(MMP.Uniform u) {
    return has_index(members, u);
}

void remove(MMP.Uniform u) {
    P3(("PSYC.Context", "remove(%O).\n", u))

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
    P3(("PSYC.Context", "casting %O.\n", p->data))
    foreach(routes; MMP.Uniform u;) {
	P4(("PSYC.Context", "casting to route %O.\n", u))
	server->deliver(u, p);
    }
}
