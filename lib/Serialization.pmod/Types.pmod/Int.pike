string base;
string type = "_int";

int(0..1) can_decode(Serialization.Atom a) {
	return a->type == "_int";
}

int decode(Serialization.Atom a) {
	int i;
	if (1 != sscanf(a->data, "%d", i)) error("Malformed integer type %O\n");
	return i;
}

Serialization.Atom encode(int i) {
	return Serialization.Atom("_method", (string)i);
}

int(0..1) can_encode(mixed a) {
    return intp(a);
}

string _sprintf(int c) {
    if (c == 'O') {
		return "Int()";
    }

    return 0;
}
