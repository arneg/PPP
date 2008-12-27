string _type;

void create(string type) {
    _type = type;
}

int(0..1) is_subtype_of(object a) {
    return Serialization.is_subtype_of(_type, a->_type);
}

int(0..1) is_supertype_of(object a) {
    return Serialization.is_supertype_of(_type, a->_type);
}

int(0..1) low_can_decode(mixed a) {
    if (object_program(a) != Serialization.Atom) return 0;
    return Serialization.is_subtype_of(a->type, _type);
}

int (0..1) low_can_encode(mixed a) {
    return 0;
}

int(0..1) can_decode(Serialization.Atom a) {
    return low_can_decode(a);
}

string _sprintf(int type) {
    if (type == 'O') {
	return sprintf("Serialization.Type(%s)", _type);
    }

    return 0;
}

int(0..1) has_action(string action) {
    return 0;
}

Serialization.Atom query() {
    return Serialization.Atom(_type+":_query", 0);
}

mixed apply(Serialization.Atom a, mixed state) {
    if (!a->action) {
	error("cannot apply data atom to a state.\n");
    }

    switch (a->action) {
    case "_query":
	return state;
    default:
	error("unsupported action.\n");
    }
}
