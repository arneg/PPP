object ktype, vtype;
string type = "_mapping";

void create(object ktype, object vtype) {
    this_program::ktype = ktype;
    this_program::vtype = vtype;
}

int(0..1) can_decode(Serialization.Atom a) {
	if (has_index(a->typed_data, this)) return 1;

	if (!a->has_pdata()) {
		a->set_pdata(Serialization.parse_atoms(a->data));
	}

	if (sizeof(a->pdata) & 1) return 0;

	for (int i = 0; i < sizeof(a->pdata); i+=2) {
		if (!ktype->can_decode(a->pdata[i])) return 0;
		if (!vtype->can_decode(a->pdata[i+1])) return 0;
	}

    return 1;
}

mapping decode(Serialization.Atom a) {
	if (has_index(a->typed_data, this)) return a->typed_date[this];

	if (!a->has_pdata()) {
		a->set_pdata(Serialization.parse_atoms(a->data));
	}

	if (sizeof(a->pdata) & 1) error("Mapping %O has odd numbered list.\n", a);

	array list = allocate(sizeof(a->pdata));

	for (int i = 0; i < sizeof(a->pdata); i+=2) {
		list[i] = ktype->decode(a->pdata[i]);
		list[i+1] = vtype->decode(a->pdata[i+1]);
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

void to_raw(Serialization.Atom a) {
	array list;
	if (!a->has_pdata()) {
		mapping m = a->typed_data[this];
		list = allocate(sizeof(m)*2);
		int i = 0;
		foreach (m; mixed key; mixed val) {
			list[i++] = ktype->encode(key);	
			list[i++] = vtype->encode(val);	
		}
		a->set_pdata(list);
	} else list = a->pdata;

	String.Buffer buf = String.Buffer();
	foreach (list;;Serialization.Atom a) {
		a->render(buf);
	}

	a->data = buf->get();
}

int(0..1) can_encode(mixed a) {
    if (!mappingp(a)) return 0;

    foreach (a; mixed key; mixed val) {
		if (!ktype->can_encode(key)) return 0;
		if (!vtype->can_encode(val)) return 0;
    }

    return 1;
}

string _sprintf(int c) {
    if (c == 'O') {
	return sprintf("Mapping(%O : %O)", ktype, vtype);
    }

    return 0;
}
