inherit .Base;

void create() {
    ::create("_json");
}

string decode(Serialization.Atom a) {
    return Standards.JSON.decode(utf8_to_string(a->data));
}

Serialization.Atom encode(mixed s) {
    return Serialization.Atom(type, string_to_utf8(Standards.JSON.encode(s)));
}

int(0..1) can_encode(mixed a) {
    return 1;
}

Serialization.StringBuilder render(mixed s, Serialization.StringBuilder buf) {
    s = encode(s);
    buf->add(sprintf("%s %d %s", type, (sizeof(s)), s));
    return buf;
}

string _sprintf(int c) {
    if (c == 'O') {
		return "JSON()";
    }

    return 0;
}
