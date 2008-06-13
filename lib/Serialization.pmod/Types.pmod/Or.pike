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
	if (type->can_decode(a))
	    return type->decode(a);
    }

    throw(({ "Cannot decode!", backtrace() }));
}

Serialization.Atom encode(array a) {
    
    foreach (types;; object type) {
	if (type->can_encode(a)) 
	    return type->encode(a);
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

    foreach (types;;object type) {
	if (type->can_encode(a)) {
	    return 1;
	}
    }

    return 0;
}

string _sprintf(int c) {
    if (c == 'O') {
	return "(" + sprintf("%O", types[*]) * " || " + ")";
    } 
    
    return 0;
}
