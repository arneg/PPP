// vim:syntax=lpc

int main(int argc, array(string) argv) {

    PSYC.Server dings = PSYC.Server(([
				    "localhosts" : ([ "dings.l.tobij.de" : 1 ]),
				    "ports" : ({ "62.75.216.40:4405" }),
				    "create_local" : create_local,
				    "create_remote" : lambda(mixed ... args) { },
				     ]));
    
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
