string _type;

void create(string type) {
    _type = type;
}

int(0..1) low_can_parse(Serialization.Atom a) {
    return Serialization.is_subtype_of(a->type, _type);
}

