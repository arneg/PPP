inherit .Base;

void create() {
    ::create("_string");
}

string decode(Serialization.Atom atom) {
    if (!can_decode(atom)) {
	error("Cannot decode %O\n", atom);
    }

    to_done(atom);
    return atom->typed_data[this];
}

Serialization.Atom encode(Serialization.Atom|string s) {
    if (low_can_decode(s)) return s;
    if (!stringp(s)) error("cannot encode non string %O\n", s);

    Serialization.Atom atom = Serialization.Atom("_string", 0);
    atom->typed_data[this] = s;
    atom->signature = this;
    
    return atom;
}

void to_done(Serialization.Atom atom) {
    if (has_index(atom->typed_data, this)) return;
    if (!stringp(atom->data)) error("No raw state.\n");

    atom->typed_data[this] = utf8_to_string(atom->data);
}

void to_raw(Serialization.Atom atom) {
    if (stringp(atom->data)) return;
    if (!has_index(atom->typed_data, this)) error("No done state.\n");

    atom->data = string_to_utf8(atom->typed_data[this]);
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
