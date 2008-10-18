inherit .Base;
object ktype, vtype;

void create(object ktype, object vtype) {
    ::create("_mapping");
    
    this_program::ktype = ktype;
    this_program::vtype = vtype;
}

mapping apply(Serialization.Atom a, mapping state) {
    if (!a->action) {
	error("cannot apply data atom to a state.\n");
    }

    mapping t;
    int create;

    switch (a->action) {
    case "_add":
	t = decode(a);
	if (!state) return t;
	return state + t;
    case "_sub":
	t = decode(a);
	if (!state) return 0; // silently ignore non-existing
	return state - t;
    case "_index_create":
	create = 1;
    case "_index":
	if (!a->pdata && !low_decode(a)) error("odd number of atoms dont make a mapping.\n");
	for (int i = 0; i < sizeof(a->pdata); i+=2) {
	    mixed key = ktype->decode(a->pdata[i]);
	    
	    if (!has_index(state, key) && !create) {
		error("indexing non-existing entry.\n");
	    }
	    
	    state[key] = vtype->handle(a->pdata[i+1], state[key]);
	}
	return state;
    default:
	error("unsupported action.\n");
    }
}

int(0..1) low_decode(Serialization.Atom a) {
    if (!a->data) a->low_render();

    object parser = Serialization.AtomParser();

    parser->feed(a->data);
    array(Serialization.Atom) list = parser->parse_all();

    if (sizeof(list) & 1) return 0;

    // we keep the array.. more convenient
    a->pdata = list;
    return 1;
}

mapping decode(Serialization.Atom a) {

    if (a->typed_data[this]) {
	return a->typed_data[this];
    }

    if (!low_can_decode(a)) error("cannot decode %O using %O.\n", a, this);

    if (!a->pdata) {
	if (!low_decode(a)) error("odd number of atoms dont make a mapping.\n");
    }

    mapping m = ([]);

    for (int i = 0; i < sizeof(a->pdata); i += 2) {
	mixed key, value;

	key = ktype->decode(a->pdata[i]);
	value = vtype->decode(a->pdata[i+1]);
	m[key] = value;
    }

    a->typed_data[this] = m;

    return m;
}

Serialization.Atom encode(Serialization.Atom|mapping m) {
    if (low_can_decode(m)) return m;
    if (!can_encode(m)) error("cannot encode %O\n", m);

    Serialization.Atom atom = Serialization.Atom("_mapping", 0);
    atom->typed_data[this] = m;
    atom->signature = this;

    return atom;
} 

string render(mapping m) {
    String.Buffer buf = String.Buffer();
    
    // we want late rendering...!!!
    // but that should probably be done when actually
    // putting stuff on the wire/hdd
    foreach (m; mixed key; mixed value) {
	ktype->encode(key)->render(buf);
	vtype->encode(value)->render(buf);
    }

    return (string)buf;
}

int(0..1) can_decode(Serialization.Atom a) {
    if (a->typed_data[this]) return 1;
    if (!a->pdata && !low_decode(a)) return 0;

    for (int i = 0; i < sizeof(a->pdata); i += 2) {

	if (!ktype->can_decode(a->pdata[i])) return 0;
	if (!vtype->can_decode(a->pdata[i+1])) return 0;
    }

    return 1;
}

int(0..1) low_can_encode(mixed a) {
    return mappingp(a);
}

int(0..1) can_encode(mixed a) {
    if (low_can_decode(a)) return 1;
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
