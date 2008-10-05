string _type;

void create(string type) {
    _type = type;
}

int(0..1) low_can_decode(Serialization.Atom a) {
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

    error("bad type in _sprintf()\n");
}
