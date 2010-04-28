string type = "_string";

string decode(Serialization.Atom a) {
	return utf8_to_string(a->data);
}

Serialization.Atom encode(string s) {
	return Serialization.Atom(type, string_to_utf8(s));
}

int(0..1) can_decode(Serialization.Atom a) {
	return a->type == type;
}

int(0..1) can_encode(mixed a) {
    return stringp(a);
}

Serialization.StringBuilder render(string s, Serialization.StringBuilder buf) {
    s = string_to_utf8(s);
    buf->add(sprintf("%s %d %s", type, (sizeof(s)), s));
    return buf;
}

string _sprintf(int c) {
    if (c == 'O') {
		return "String()";
    }

    return 0;
}
