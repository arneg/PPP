mapping targets = ([ ]);
mapping connections = ([ ]);

int main(int argc, array(string) argv) {

    Stdio.Port p = Stdio.Port(4404, accept);
    p->set_id(p);
    
    return -1;
}

void accept(Stdio.Port _) {
    string peerhost;
    Stdio.File __;
    write("%O\n", _);
    __ = _->accept();
    peerhost = __->query_address();
    
    connections[peerhost] = MMP.Circuit(__, deliver, clo_sec);
}

void clo_sec(MMP.Circuit c) {
    MMP.mmp_p p;

    m_delete(connections, p->socket->peerhost);
    
    while (!c->isEmpty()) {
	p = c->shift();
	deliver(p);
    }
}

void register_target(string target, object o) {
    if (has_index(targets, target)) {
	write("ERROR ERROR ERROR TARGET OVERWRITING IS AN ERROR ERROR ERROR\n");
	return;
    }

    targets[target] = o;
}

void unregister_target(string target) {
    m_delete(targets, target);
}

object find_target(string target) {
    return targets[target];
}

// does _not_ check whether the uni->host is local.
object create_local(PSYC.uniform uni) {
    object o;
    if (sizeof(uni->resource) > 1) switch (uni->resource[0]) {
    case '~':
	// TODO check for the path...
	o = User.Person(uni->resource[1..], uni->unl);
	return o;
	break;
    case '@':
	break;
    case '$':
    }
}

void if_localhost(string host, function if_cb, function else_cb, 
		  mixed ... args ) {
    if (host == "localhost")
	if_cb(args);
    else
	else_cb(args);
}

void deliver(MMP.mmp_p p) {
    mixed t = p["_target"];
    
    if (t) {

	if (stringp(t)) {
	    t = PSYC.parse_uniform(t);

	    p["_target"] = t;
	}

	if_localhost(p["_target"]->host, deliver_local, deliver_remote, p); 
    } else {
	write("I dont know how to deliver this!");
    }
}

void deliver_remote(MMP.mmp_p p) {
    // find the connection orr.... queue it

}

void deliver_local(MMP.mmp_p p) {
    object o;
    mixed t;
    mixed packet;

    // this is much to unflexible.. but as a first approach. 
    t = p["_target"];
    o = find_target(t);
    
    if (!o) {
	o = create_local(t);		
    }
    
    packet = PSYC.parse(p->data);

    o->msg(packet);
}
