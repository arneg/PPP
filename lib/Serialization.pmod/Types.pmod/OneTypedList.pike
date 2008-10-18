inherit .Base;
object type;
object index;

void create(object type) {
    ::create("_list");
    
    this_program::type = type;
}

array apply(Serialization.Atom a, array state) {
    if (!a->action) {
	error("cannot apply data atom to a state.\n");
    }

    array t;

    switch (a->action) {
    case "_add":
	t = decode(a);
	if (!state) return t;
	return state + t;
    case "_sub":
	t = decode(a);
	if (!state) return 0; // silently ignore non-existing
	return state - t;
    case "_index":
	if (!a->pdata) low_decode(a);
	if (sizeof(a->pdata) & 1) error("need index+action.\n");

	// this is baad!
	if (!index) index = Serialization.Types.Int();
	for (int i = 0; i < sizeof(a->pdata); i+=2) {
	    int key = index->decode(a->pdata[i]);
	    
	    if (key >= sizeof(state)) {
		error("indexing non-existing entry.\n");
	    }
	    
	    state[key] = type->handle(a->pdata[i+1], state[key]);
	}
	return state;
    default:
	error("unsupported action.\n");
    }
}

string render(array a) {
    String.Buffer buf = String.Buffer();
    
    foreach (a; ;mixed value) {
	type->encode(value)->render(buf);
    }

    return (string)buf;
}

array decode(Serialization.Atom a) {
    array list;

    if (a->typed_data[this]) {
	return a->typed_data[this];
    }

    if (!low_can_decode(a)) error("bad atom.");
    if (!a->pdata) {
	low_decode(a);
    }

    list = allocate(sizeof(a->pdata));

    foreach (a->pdata;int i;Serialization.Atom item) {
	list[i] = type->decode(item);
    }

    return list;
}

// dont use this
// TODO: may not throw due to can_decode
void low_decode(Serialization.Atom a) {
    if (!a->data) a->low_render();

    object parser = Serialization.AtomParser();

    parser->feed(a->data);
    a->pdata = parser->parse_all();
}

Serialization.Atom encode(Serialization.Atom|array a) {
    if (low_can_decode(a)) return a;
    // we want late rendering...!!!
    foreach (a;; mixed t) {
	if (!type->can_encode(t)) {
	    error("%O cannot encode %O.", type, t);
	}
    }

    Serialization.Atom atom = Serialization.Atom("_list", 0);
    atom->typed_data[this] = a;
    atom->signature = this;

    return atom;
}

int(0..1) can_decode(Serialization.Atom a) {
    if (a->typed_data[this]) return 1;
    if (!low_can_decode(a)) return 0;
    if (!a->pdata) low_decode(a);

    foreach (a->pdata;;Serialization.Atom i) {
	if (!type->can_decode(i)) return 0;
    }

    return 1;
}

int (0..1) low_can_encode(mixed a) {
    return arrayp(a);
}

int(0..1) can_encode(mixed a) {
    if (low_can_decode(a)) return 1;
    if (!arrayp(a)) {
	return 0;
    }

    foreach (a;;mixed i) {
	if (!type->can_encode(i)) {
	    return 0;
	}
    }

    return 1;
}

string _sprintf(int c) {
    if (c == 'O') {
	return sprintf("List(%O)", type);
    }

    return 0;
}
