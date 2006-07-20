// vim:syntax=lpc
//
PSYC.Server dings;

int main(int argc, array(string) argv) {

    dings = PSYC.Server(([
	"localhosts" : ([ "dings.l.tobij.de" : 1 ]),
	"ports" : ({ "62.75.216.40:4405" }),
	"create_local" : create_local,
	"create_remote" : lambda(mixed ... args) { },
	"module_factory" : create_module,
	"offer_modules" : ({ "_compress" }),
	 ]));
    return -1;
}

// does _not_ check whether the uni->host is local.
object create_local(PSYC.uniform uni) {
    object o;
    if (sizeof(uni->resource) > 1) switch (uni->resource[0]) {
    case '~':
	// TODO check for the path...
	o = User.Person(uni->resource[1..], uni->unl, dings);
	return o;
	break;
    case '@':
	return Place.Basic(uni->unl, dings);
	break;
    case '$':
    }
}


// we transmit the variables of the neg packet. i dont have a better idea
// right now
object create_module(string name, mapping vars) {

    switch (name) {
    case "_compress":
	
    case "_encrypt":

    }

}
