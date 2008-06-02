string _type;

void create(string type) {
    _type = type;
}

int(0..1) can_decode(Serialization.Atom a) {
    return Serialization.is_subtype_of(a->type, _type);
}

int (0..1) can_encode(mixed a) {
    return 0;
}
