object ktype, vtype;
string type = "_mapping";

void create(object ktype, void|object vtype) {
    this_program::ktype = ktype;
    this_program::vtype = vtype;
}

int(0..1) can_decode(Serialization.Atom a) {
	if (has_index(a->typed_data, this)) return 1;

	return a->type == "_mapping";
}

mapping decode(Serialization.Atom a) {
	if (has_index(a->typed_data, this)) return a->typed_data[this];

	array list = Serialization.parse_atoms(a->data);

	if (sizeof(list) & 1) error("Mapping %O has odd numbered list.\n", a);

	for (int i = 0; i < sizeof(list); i++) {
		list[i] = ktype->decode(list[i]);
		i++;
		list[i] = vtype->decode(list[i]);
	}

	mapping m = aggregate_mapping(@list);
	a->set_typed_data(this, m);
	return m;
}

Serialization.Atom encode(mapping m) {
	Serialization.Atom atom = Serialization.Atom("_mapping", 0);
	atom->set_typed_data(this, m);
	return atom;
}

string render_payload(Serialization.Atom atom) {
    mapping m = atom->get_typed_data(this);
    MMP.Utils.StringBuilder buf = MMP.Utils.StringBuilder();

    foreach (m; mixed key; mixed value) {
		ktype->render(key, buf);
		vtype->render(value, buf);
    }

    return buf->get();
}

MMP.Utils.StringBuilder render(mapping m, MMP.Utils.StringBuilder buf) {
    int|array node = buf->add();
	int length = buf->length();

    foreach (m; mixed key; mixed value) {
		ktype->render(key, buf);
		vtype->render(value, buf);
    }

    buf->set_node(node, sprintf("%s %d ", type, buf->length() - length));

    return buf;
}

int(0..1) can_encode(mixed a) {
    return mappingp(a);
}

string _sprintf(int c) {
    if (c == 'O') {
	return sprintf("Mapping(%O : %O)", ktype, vtype);
    }

    return 0;
}
