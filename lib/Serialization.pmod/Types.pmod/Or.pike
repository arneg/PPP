inherit .Base;
array(object) types;

void create(object ... types) {
    ::create("");
    
    this_program::types = types;
}

array decode(Serialization.Atom a) {
    if (!low_can_decode(a)) throw(({}));

    if (!a->parsed) low_decode(a);

    foreach (a->pdata;int i;Serialization.Atom item) {
	list[i] = type->decode(item);
    }

    return list;
}

int (0..1) low_can_decode(mixed a) {
    return 1;
}

int (0..1) low_can_encode(mixed a) {
    return 1;
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
    
    foreach (types;; object type) {
	if (type->can_encode(a)) 
	    return Serialization.render_atom(type->encode(t), buf);
    }

    throw(({ "cannot encode this!", backtrace() }));
}

int(0..1) can_decode(Serialization.Atom a) {

    foreach (types;;object type) {
	if (type->can_decode(a)) return 1;
    }

    return 0;
}


int(0..1) can_encode(mixed a) {

    foreach (a;;object type) {
	if (type->can_encode(a)) {
	    return 1;
	}
    }

    return 0;
}
