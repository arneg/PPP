inherit .Base;
object type;

void create(object type) {
    ::create("_list");
    
    this_program::type = type;
}

array decode(Serialization.Atom a) {
    if (!low_can_decode(a)) throw(({}));

    if (!a->parsed) low_decode(a);

    foreach (a->pdata;int i;Serialization.Atom item) {
	list[i] = type->decode(item);
    }

    return list;
}

// dont use this
void low_decode(Serialization.Atom a) {
    if (a->parsed) {
	// useless call. warn. someone
    }

    object parser = Serialization.AtomParser();

    parser->feed(a->data);
    a->pdata = parser->parse_all();
    a->parsed = 1;
}

Serialization.Atom encode(array a) {
    String.Buffer buf = String.Buffer();
    
    // we want late rendering...!!!
    foreach (a;; mixed t) {
	Serialization.render_atom(type->encode(t), buf);
    }

    return Serialization.Atom("_list", (string)buf);
}

int(0..1) can_decode(Serialization.Atom a) {
    if (!a->parsed) low_decode(a);

    foreach (a->pdata;;Serialization.Atom i) {
	if (!type->can_decode(i)) return 0;
    }

    return 1;
}

int (0..1) low_can_encode(mixed a) {
    return arrayp(a);
}

int(0..1) can_encode(mixed a) {
    if (!arrayp(a)) {
	return 0;
    }

    foreach (a;;mixed i) {
	if (!type->can_encode(a)) {
	    return 0;
	}
    }

    return 1;
}
