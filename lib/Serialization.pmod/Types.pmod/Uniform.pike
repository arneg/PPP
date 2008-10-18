inherit .Base;

object server;

void create(object server) {
    ::create("_uniform");

    this_program::server = server;
}

MMP.Uniform decode(Serialization.Atom a) {
    if (a->typed_data[this]) return a->typed_data[this];

    if (!can_decode(a)) error("cannot decode %O\n", a);

    if (!a->data) low_render();

    return server->get_uniform(a->data);
}

Serialization.Atom encode(MMP.Uniform u) {
    if (low_can_decode(u)) return u;
    if (!MMP.is_uniform(u)) error("cannot encode %O\n", u);

    object a = Serialization.Atom("_uniform", 0);
    a->typed_data[this] = u;
    return a;
}

string render(MMP.Uniform u) {
    return (string)u;
}

int(0..1) can_encode(mixed a) {
    if (low_can_decode(u)) return 1;
    return MMP.is_uniform(a);
}

string _sprintf(int c) {
    if (c == 'O') {
	return "Uniform()";
    }

    return 0;
}
