inherit .Base;

object method, vars, data;
int length = 1;

void create(object method, void|object vars, void|object data) {
    ::create("_psyc_packet"); 

    this_program::method = method;

    if (data) {
	this_program::data = data;
	length++;
    }

    if (vars) {
	this_program::vars = vars;
	length++;
    }
}

void low_decode(Serialization.Atom a) {
    if (a->parsed) {
        return;
    }

    object parser = Serialization.AtomParser();

    parser->feed(a->data);
    array(Serialization.Atom) list = parser->parse_all();

    if (sizeof(list) != length) error("bad _psyc_packet: %O\n", a);

    // we keep the array.. more convenient
    a->pdata = list;
    a->parsed = 1;
}

PSYC.Packet decode(Serialization.Atom a) {
    if (!low_can_decode(a)) error("expected _psyc_packet, got %s\n", a->type);

    if (!a->parsed) low_decode(a);

    array t = a->pdata;
    int i = 1;

    string mc = method->decode(t[0]);
    mapping v;
    mixed d;
    if (vars) {
	v = vars->decode(t[i++]);
    }
    if (data) {
	d = data->decode(t[i]);
    }

    return PSYC.Packet(mc, v, d);
}

Serialization.Atom encode(PSYC.Packet p) {
    if (!can_encode(p)) error("%O cannot encode packet %O\n", this, p);

    String.Buffer buf = String.Buffer();
     Serialization.render_atom(method->encode(p->mc), buf);
     if (vars) {
	 Serialization.render_atom(vars->encode(p->vars), buf);
     }
     if (data) {
	 Serialization.render_atom(data->encode(p->data), buf);
     }

     return Serialization.Atom("_psyc_packet", buf->get());
}

int(0..1) can_decode(Serialization.Atom a) {
    if (!low_can_decode(a)) return 0;

    if (!a->parsed) low_decode(a);

    array t = a->pdata;
    int i = 1;
    return (method->can_decode(t[0]) && (!vars || vars->can_decode(t[i++])) && (!data || data->can_decode(t[i])));
}

int(0..1) low_can_encode(object p) {
    return (has_index(p, "mc") && has_index(p, "data") && has_index(p, "vars"));
}

int(0..1) can_encode(object p) {
    if (!low_can_encode(p)) return 0;

    // TODO: this is not quite right.
    return (method->can_encode(p->mc) && ((!data && !sizeof(p->data)) || (data && data->can_encode(p->data))) && ((!vars && !sizeof(p->vars)) || (vars && vars->can_encode(p->vars))));
}

string _sprintf(int c) {
    if (c == 'O') {
	return sprintf("Serialization.Packet(%O, %O, %O)", method, vars, data);
    }

    return 0;
}
