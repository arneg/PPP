inherit .Base;

object data, vars;

void create(object data, object vars) {
    ::create("_mmp_packet"); 

    this_program::data = data;
    this_program::vars = vars;
}

void low_decode(Serialization.Atom a) {
    if (a->parsed) {
        return;
    }

    object parser = Serialization.AtomParser();

    parser->feed(a->data);
    array(Serialization.Atom) list = parser->parse_all();

    if (sizeof(list) > 2) error("bad _mmp_packet: %O\n", a);

    // we keep the array.. more convenient
    a->pdata = list;
    a->parsed = 1;
}

MMP.Packet decode(Serialization.Atom a) {
    if (!low_can_decode(a)) error("expected _mmp_packet, got %s\n", a->type);

    if (!a->parsed) low_decode(a);

    array t = a->pdata;
    int i = 1;

    mapping v;
    mixed d;
    v = vars->decode(t[0]);

    if (data) {
	d = data->decode(t[1]);
    }

    return MMP.Packet(d, v);
}

Serialization.Atom encode(PSYC.Packet p) {
    if (!can_encode(p)) error("%O cannot encode packet %O\n", this, p);

    String.Buffer buf = String.Buffer();
     Serialization.render_atom(vars->encode(p->vars), buf);

     if (data) {
	 Serialization.render_atom(data->encode(p->data), buf);
     }

     return Serialization.Atom("_mmp_packet", buf->get());
}

int(0..1) can_decode(Serialization.Atom a) {
    if (!low_can_decode(a)) return 0;

    if (!a->parsed) low_decode(a);

    array t = a->pdata;
    return (vars->can_decode(t[0]) && ((!data && sizeof(t) == 1) || (sizeof(t) == 2 && data->can_decode(t[1]))));
}

int(0..1) low_can_encode(object p) {
    return (has_index(p, "data") && has_index(p, "vars"));
}

int(0..1) can_encode(object p) {
    if (!low_can_encode(p)) return 0;

    return (vars->can_encode(p->vars) && ((!data && p->data) || (data && data->can_encode(p->data))));
}

string _sprintf(int c) {
    if (c == 'O') {
	return sprintf("Serialization.MMPPacket(%O, %O, %O)", method, vars, data);
    }

    return 0;
}
