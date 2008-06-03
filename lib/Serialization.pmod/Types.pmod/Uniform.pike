inherit .Base;

object server;

void create(object server) {
    ::create("_uniform");

    this_program::server = server;
}

MMP.Uniform decode(Serialization.Atom a) {
    if (can_decode(a)) {
	return server->get_uniform(a->data);
    }

    throw(({}));
}

Serialization.Atom encode(MMP.Uniform u) {
    if (MMP.is_uniform(u)) {
	object a = Serialization.Atom("_uniform", (string)u);
	a->parsed = 1;
	a->pdata = u;

	return 0;
    }

    throw(({}));
}

int(0..1) can_encode(mixed a) {
    return MMP.is_uniform(a);
}
