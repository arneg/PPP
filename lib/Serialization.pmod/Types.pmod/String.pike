inherit .Base;

void create() {
    ::create("_string");
}

string decode(Serialization.Atom a) {
    if (can_decode(a)) {
	return utf8_to_string(a->data);
    }

    throw(({}));
}

Serialization.Atom encode(string s) {
    if (stringp(s)) {
	return Serialization.Atom("_string", string_to_utf8(s));
    }

    throw(({}));
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
