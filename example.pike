// vim:syntax=lpc
mapping targets = ([ ]);
mapping connections = ([ ]);

int main(int argc, array(string) argv) {

    
    return -1;
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
