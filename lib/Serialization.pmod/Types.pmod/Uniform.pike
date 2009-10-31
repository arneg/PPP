inherit .Base;

object server;

void create(object server) {
    ::create("_uniform");

    this_program::server = server;
}

MMP.Uniform get_uniform(string s) {
    if (server) return server->get_uniform(s);
    else return MMP.Uniform(s);
}

void raw_to_medium(Serialization.Atom atom) {
    atom->pdata = get_uniform(atom->data);
}

void medium_to_raw(Serialization.Atom atom) {
    if (!MMP.is_uniform(atom->pdata)) error("cannot encode %O\n", atom->pdata);
    atom->data = (string)atom->pdata;
}

int(0..1) can_encode(mixed a) {
    return MMP.is_uniform(a);
}

string _sprintf(int c) {
    if (c == 'O') {
		return "Uniform()";
    }

    return 0;
}
