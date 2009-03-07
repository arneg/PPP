inherit .Base;

string base;

void create(void|string base) {
    ::create("_method");

    if (base) this_program::base = base;
}

string decode(Serialization.Atom atom) {
    to_done(atom);
    return atom->typed_data[this];
}

Serialization.Atom encode(string s) {
    if (!can_encode(s)) error("cannot encode %O to a method.", s);

    return Serialization.Atom("_method", s);
}

int(0..1) can_encode(mixed s) {
    return stringp(s) && String.width(s) == 8 && (!base || has_prefix(s, base));
}

void to_raw(Serialization.Atom atom) { 
    if (stringp(atom->data)) return;
    if (!has_index(atom->typed_data, this)) error("No done state.\n");
    atom->data = atom->typed_data[this];
}

void to_done(Serialization.Atom atom) { 
    if (has_index(atom->typed_data, this)) return;
    if (!stringp(atom->data)) error("No raw state.\n");

    if (can_decode(atom) && (!base || has_prefix(atom->data, base))) {
	atom->typed_data[this] = atom->data;
	return;
    }

    error("cannot decode %O to a method.", atom);
}

string _sprintf(int type) {
    if (type == 'O') {
	if (base) {
	    return sprintf("Serialization.Method(%s)", base);
	} else {
	    return ::_sprintf(type);
	}
    }

    return 0;
}
