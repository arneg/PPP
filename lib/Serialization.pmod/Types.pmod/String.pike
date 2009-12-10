string decode(Serialization.Atom a) {
	return utf8_to_string(a->data);
}

Serialization.Atom encode(string s) {
	return Serialization.Atom("_string", string_to_utf8(s));
}

int(0..1) can_decode(Serialization.Atom a) {
	return a->type == "_string";
}

int(0..1) can_encode(mixed a) {
    return stringp(a);
}

string _sprintf(int c) {
    if (c == 'O') {
		return "String()";
    }

    return 0;
}
