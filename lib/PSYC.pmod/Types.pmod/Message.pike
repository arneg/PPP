inherit Serialization.Types.Base;
object method, data, vars;

void create(object vars, object data) {
	this_program::vars = vars;
	this_program::data = data;
}

// dont use this
// TODO: may not throw due to can_decode
string render_payload(Serialization.Atom atom) {
	PSYC.Message m = atom->get_typed_data(this);
	Serialization.StringBuilder buf = Serialization.StringBuilder();

	vars->render(m->vars, buf);
	data->render(m->data, buf);


	return buf->get();
}

Serialization.Atom encode(PSYC.Message m) {
    Serialization.Atom a = ::encode(m);
    a->type = m->method;
    return a;
}

Serialization.StringBuilder render(PSYC.Message m, Serialization.StringBuilder buf) {
	array node = buf->add();

	vars->render(m->vars, buf);
	data->render(m->data, buf);
	node[2] = sprintf("%s %d ", m->method, buf->count_length(node));

	return buf;
}

PSYC.Message decode(Serialization.Atom atom) {
	object m = atom->get_typed_data(this);

	if (m) return m;
	
	m = PSYC.Message();
	array(Serialization.Atom) list = Serialization.parse_atoms(atom->data);

	m->method = atom->type;

	if (sizeof(list) != 2) error("broken pdata: %O\n", list);

	m->vars = vars->decode(list[0]);
	m->data = data->decode(list[1]);

	atom->set_typed_data(this, m);

	return m;
}

int(0..1) can_decode(Serialization.Atom atom) {
    string family = Serialization.subtypes(atom->type)[1];
    switch (family) {
    case "_message":
    case "_notice":
    case "_request":
    case "_error":
    case "_status":
    	return 1;
    }
    return 0;
}

int (0..1) can_encode(mixed a) {
	return Program.inherits(object_program(a), PSYC.Message);
}
