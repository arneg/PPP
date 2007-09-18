// vim:syntax=lpc
#include <new_assert.h>

inherit MMP.Utils.Debug;

object server;
multiset(MMP.Uniform) members = (<>);
mapping(MMP.Uniform:int) routes = ([]);
mapping options;
int count = 0;


// TODO: 
// - doesnt know who he is and therefore needs to know the route to the
//   context
// - think about the local checks.

void create(mapping params) {
    ::create(params["debug"]);

    assert(objectp(server = params["server"]));
}

void insert(MMP.Uniform u, function cb, mixed ... args) {
    debug("multicast_routing", 3, "insert(%O).\n", u);

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
    debug("multicast_routing", 3, "remove(%O).\n", u);

    while (members[u]--);
    if (u->is_local()) {
	m_delete(routes, u);
	return;
    } else {
	if (has_index(routes, u->root)) {
	    if (routes[u->root] <= 1) {
		m_delete(routes, u->root);
	    } else {
		routes[u->root]--;
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
    debug(([ "packet_flow" : 3, "multicast_routing" : 3 ]), "casting %O.\n", p->data);
    foreach(routes; MMP.Uniform u;) {
	debug(([ "packet_flow" : 4, "multicast_routing" : 4 ]), "casting to route %O.\n", u);
	server->deliver(u, p);
    }
}
