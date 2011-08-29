inherit .Base;

mixed value;

void create(string type, mixed v) {
    ::create(type);
    value = v;
}

Serialization.Atom encode(mixed o) {
    return Serialization.Atom(type, "");
}

mixed decode(Serialization.Atom atom) {
    return value;
}

Serialization.StringBuilder render(mixed o, Serialization.StringBuilder buf) {
    buf->add(type+" 0 ");
    return buf;
}

int(0..1) can_encode(mixed o) { return o == value; }
