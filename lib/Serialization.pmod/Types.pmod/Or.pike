inherit .Base;
array(object) types;

void create(object ... types) {
    ::create("");
    
    this_program::types = types;
}

int (0..1) low_can_decode(mixed a) {
    return 1;
}

int (0..1) low_can_encode(mixed a) {
    return 1;
}

array decode(Serialization.Atom a) {

    foreach (types;;object type) {
	if (type->can_decode(item)
	    return type->decode(item);
    }

    throw(({ "Cannot decode!", backtrace() }));
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
