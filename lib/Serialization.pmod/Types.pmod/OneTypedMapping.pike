inherit .Base;
object ktype, vtype;

void create(object ktype, object vtype) {
    ::create("_mapping");
    
    this_program::ktype = ktype;
    this_program::vtype = vtype;
}

array decode(Serialization.Atom a) {
    if (!can_decode(a)) throw(({}));

    object parser = Serialization.AtomParser();

    parser->feed(a->data);
    array(Serialization.Atom) list = parser->parse_all();

    if (sizeof(list) & 1) throw(({}));

    mapping m = ([]);

    for (int i = 0; i < sizeof(list); i += 2) {
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
    // sending putting stuff on the wire/hdd
    foreach (m; mixed key; mixed value) {
	Serialization.render_atom(ktype->encode(key), buf);
	Serialization.render_atom(vtype->encode(value), buf);
    }

    return Serialization.Atom("_mapping", (string)buf);
}

int(0..1) can_encode(mixed a) {
    return mappingp(a);
}
