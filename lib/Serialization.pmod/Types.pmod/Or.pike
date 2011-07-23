array(object) types;
function|program constructor;

void create(object ... types) {
    this_program::types = types;
    this_program::constructor = constructor;
}

int(0..1) can_decode(Serialization.Atom a) {
    foreach (types;;object type)
	if (type->can_decode(a)) return 1;
    return 0;
}

int(0..1) can_encode(mixed o) {
    foreach (types;;object type)
	if (type->can_encode(o)) return 1;
    return 0;
}

int decode(Serialization.Atom a) {
    mixed e;
    foreach (types;;object type)
	if (type->can_decode(a)) {
	    mixed err = catch { return type->decode(a); };
	    if (err) e = err;
	}
    error("Cannot decode %O (%O)\n", a, e);
}

Serialization.Atom encode(mixed o) {
    mixed error;
    foreach (types;;object type)
	if (type->can_encode(o)) {
	    mixed err = catch { return type->encode(o); };
	    if (err) error = err;
	}
    predef::error("Cannot encode %O (%O)\n", o, error);
}

string _sprintf(int c) {
    if (c == 'O') {
	return sprintf("Or(%O)", types);
    }

    return 0;
}

void render(mixed o, String.Buffer buf) {
    encode(o)->render(buf);
}
