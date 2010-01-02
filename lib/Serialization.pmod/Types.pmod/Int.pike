string base;
string type = "_integer";

int(0..1) can_decode(Serialization.Atom a) {
	return a->type == type;
}

int decode(Serialization.Atom a) {
	int i;
	if (1 != sscanf(a->data, "%d", i)) error("Malformed integer type %O\n");
	return i;
}

Serialization.Atom encode(int i) {
	return Serialization.Atom(type, (string)i);
}

int(0..1) can_encode(mixed a) {
    return intp(a);
}

MMP.Utils.StringBuilder render(int i, MMP.Utils.StringBuilder buf) {
    string s = (string)i;
    buf->add(sprintf("%s %d %s", type, (sizeof(s)), s));
    return buf;
}

string _sprintf(int c) {
    if (c == 'O') {
		return "Int()";
    }

    return 0;
}
