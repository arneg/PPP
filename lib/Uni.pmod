// a simple class inherited by everyone having an address..
//

string uni;

void create(string u) {
    uni = u;
}

// mixed target for objects?? i dont like something about that. even though
// we would have one more hashlookup
void sendmsg(string target, string mc, string|void data, mapping|void vars) {

    if (!vars) vars = ([ "_target" : target ]);
    else vars["_target"] = target;

    // duality of mmp and psyc packets is a problem again. putting target into
    // psyc-vars is of plain wronginess.
    send(PSYC.psyc_p(mc, data, vars));
}

void send(PSYC.psyc_p p) {
    
}
