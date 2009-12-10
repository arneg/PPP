object server;
string type = "_uniform";

void create(object server) {
    this_program::server = server;
}

MMP.Uniform get_uniform(string s) {
    if (server) return server->get_uniform(s);
    else return MMP.Uniform(s);
}

int(0..1) can_encode(mixed a) {
    return MMP.is_uniform(a);
}

int(0..1) can_decode(Serialization.Atom a) {
	return a->type == "_uniform";
}

MMP.Uniform decode(Serialization.Atom a) {
	return get_uniform(a->data);
}

Serialization.Atom encode(MMP.Uniform u) {
	return Serialization.Atom("_uniform", (string)u);
}

string _sprintf(int c) {
    if (c == 'O') {
		return "Uniform()";
    }

    return 0;
}
