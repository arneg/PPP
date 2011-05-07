string type = "_false";

int(0..1) can_decode(Serialization.Atom a) {
    return a->type == type;
}

int decode(Serialization.Atom a) {
    return 0;
}

Serialization.Atom encode(int i) {
    return Serialization.Atom(type, "");
}

int(0..1) can_encode(mixed a) {
    return !a;
}

Serialization.StringBuilder render(int i, Serialization.StringBuilder buf) {
    buf->add("_false 0 ");
    return buf;
}

string _sprintf(int c) {
    if (c == 'O') {
	return "False()";
    }

    return 0;
}
