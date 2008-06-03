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

function can_decode = low_can_decode;
