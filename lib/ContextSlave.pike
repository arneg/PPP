object server;
multiset members = (<>);

void create(object s) {
    server = s;
}

void insert(MMP.Uniform u) {
    members[u] = 1;
}

void remove(MMP.Uniform u) {
    members[u] = 0;
}

void castmsg(MMP.Packet p) {
    foreach(members; MMP.Uniform u;) {
	server->deliver(u, p);
    }
}
