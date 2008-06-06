inherit .Base;
array(object) ktypes, vtypes;

void create(array(object) ktypes, void|array(object) vtypes) {
    ::create("_mapping");
    
    if (!arrayp(vtypes)) {
	if (sizeof(ktypes) & 1) {
	    throw(({ "help. no mapping", backtrace() }));
	}

	array t = ktypes;
	vtypes = allocate(sizeof(t) / 2);
	ktypes = allocate(sizeof(t) / 2);

	for (int i = 0; i < sizeof(t); i += 2) {
	    ktypes[i/2] = t[i];
	    vtypes[i/2] = t[i+1];
	}
    } else if (sizeof(vtypes) != sizeof(ktypes)) {
	throw(({ "not a proper mapping def.", backtrace() }));
    }

    this_program::ktypes = ktypes;
    this_program::vtypes = vtypes;
}

void low_decode(Serialization.Atom a) {
    if (a->parsed) {
	return 0;
    }

    object parser = Serialization.AtomParser();

    parser->feed(a->data);
    array(Serialization.Atom) list = parser->parse_all();

    if (sizeof(list) & 1) throw(({}));

    // we keep the array.. more convenient
    a->pdata = list;
    a->parsed = 1;
}

mapping decode(Serialization.Atom a) {
    if (!low_can_decode(a)) throw(({}));

    if (!a->parsed) low_decode(a);

    mapping m = ([]);

    for (int i = 0; i < sizeof(a->pdata); i += 2) {
	mixed key, value;
	int ok;

	foreach (ktypes;int i; object ktype) {
	    if (ktype->can_decode(a->pdata[i]) && vtypes[i]->can_decode(a->pdata[i+1])) {
		key = ktype->decode(a->pdata[i]);
		value = vtypes[i]->decode(a->pdata[i+1]);
		ok = 1;
		break;
	    }
	}

	if (!ok) {
	    throw(({ "Could not decode!", backtrace() }));
	}

	m[key] = value;
    }

    return m;
}

Serialization.Atom encode(mapping m) {
    String.Buffer buf = String.Buffer();
    
    // we want late rendering...!!!
    // but that should probably be done when actually
    // putting stuff on the wire/hdd
    foreach (m; mixed key; mixed value) {
	int ok;

	foreach (ktypes;int i;object ktype) {
	    if (ktype->can_encode(key) && vtypes[i]->can_encode(value)) {
		Serialization.render_atom(ktype->encode(key), buf);
		Serialization.render_atom(vtypes[i]->encode(value), buf);
		ok = 1;
		break;
	    }
	}

	if (!ok) {
	    throw(({ "Could not encode mapping!", backtrace() }));
	}
    }

    return Serialization.Atom("_mapping", (string)buf);
}

int(0..1) can_decode(Serialization.Atom a) {
    if (!low_can_decode(a)) return 0;
    if (!a->parsed) low_decode(a);

    for (int i = 0; i < sizeof(a->pdata); i += 2) {
	int ok;

	foreach (ktypes; int i; object ktype) {
	    if (ktype->can_decode(a->pdata[i]) && vtypes[i]->can_decode(a->pdata[i+1])) {
		ok = 1;
		break;
	    }
	}

	if (!ok) return 0;
    }

    return 1;
}

int(0..1) low_can_encode(mixed a) {
    return mappingp(a);
}

int(0..1) can_encode(mixed a) {
    if (!mappingp(a)) return 0;

    foreach (a; mixed key; mixed value) {
	int ok;

	foreach (ktypes; int i; object ktype) {
	    if (ktype->can_encode(key) && vtypes[i]->can_encode(value)) {
		ok = 1;
		break;
	    }
	}

	if (!ok) return 0;
    }

    return 1;
}

string _sprintf(int c) {
    if (c == 'O') {
	return sprintf("Mapping(%O)", mkmapping(ktypes, vtypes));
    }

    return "";
}
