object server;
multiset members = (<>);
mapping routes = ([]);

void create(object s) {
    server = s;
}

void insert(MMP.Uniform u) {
    members[u] = 1;
    routes[u->handler]++;
}

void remove(MMP.Uniform u) {
    members[u] = 0;

    if (has_index(routes, u->handler)) {
	if (
    }
}

int _sizeof() {
    return sizeof(members);
}

void msg(MMP.Packet p) {
    foreach(members; MMP.Uniform u;) {
	server->deliver(u, p);
    }
}
