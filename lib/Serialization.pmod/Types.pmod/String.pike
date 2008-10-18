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

Serialization.Atom encode(Serialization.Atom|string s) {
    if (low_can_decode(s)) return s;
    if (!stringp(s)) error("cannot encode non string %O\n", s);

    Serialization.Atom atom = Serialization.Atom("_string", 0);
    atom->typed_data[this] = s;
    atom->signature = this;
    
    return atom;
}

function render = string_to_utf8;

int(0..1) can_encode(mixed a) {
    if (low_can_decode(a)) return 1;
    return stringp(a);
}

string _sprintf(int c) {
    if (c == 'O') {
	return "String()";
    }

    return 0;
}
