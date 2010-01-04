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
	return a->type == type;
}

MMP.Uniform decode(Serialization.Atom a) {
	return get_uniform(a->data);
}

Serialization.Atom encode(MMP.Uniform u) {
	return Serialization.Atom(type, (string)u);
}

MMP.Utils.StringBuilder render(MMP.Uniform uniform, MMP.Utils.StringBuilder buf) {
    string s = (string)uniform;
    buf->add(sprintf("%s %d %s", type, (sizeof(s)), s));
    return buf;
}

string _sprintf(int c) {
    if (c == 'O') {
		return "Uniform()";
    }

    return 0;
}
