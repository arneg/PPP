inherit .Base;
object ktype, vtype;

void create(object ktype, object vtype) {
    ::create("_mapping");
    
    this_program::ktype = ktype;
    this_program::vtype = vtype;
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

array decode(Serialization.Atom a) {
    if (!can_decode(a)) throw(({}));

    if (!a->parsed) low_decode(a);

    mapping m = ([]);

    for (int i = 0; i < sizeof(a->pdata); i += 2) {
	mixed key, value;

	key = ktype->decode(list[i]);
	value = vtype->decode(list[i+1]);
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
	Serialization.render_atom(ktype->encode(key), buf);
	Serialization.render_atom(vtype->encode(value), buf);
    }

    return Serialization.Atom("_mapping", (string)buf);
}

int(0..1) can_decode(Serialization.Atom a) {
    if (!a->parsed) low_decode(a);

    for (int i = 0; i < sizeof(a->pdata); i += 2) {

	if (!ktype->can_decode(list[i])) return 0;
	if (!vtype->can_decode(list[i+1])) return 0;
    }

    return 1;
}

int(0..1) low_can_encode(mixed a) {
    return mappingp(a);
}

int(0..1) can_encode(mixed a) {
    if (!mappingp(a)) return 0;

    foreach (a; mixed key; mixed val) {
	if (!ktype->can_encode(key)) return 0;
	if (!vtype->can_encode(val)) return 0;
    }

    return 1;
}
