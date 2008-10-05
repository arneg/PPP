inherit .Base;

string base;

void create(void|string base) {
    ::create("_method");

    if (base) this_program::base = base;
}

string decode(Serialization.Atom a) {
    if (can_decode(a) && (!base || has_prefix(a->data, base))) {
	return a->data;
    }

    error("cannot decode %O to a method.", a);
}

Serialization.Atom encode(string s) {
    if (stringp(s) && String.width(s) == 8 && (!base || has_prefix(s, base))) {
	return Serialization.Atom("_method", s);
    }

    error("cannot encode %O to a method.", s);
}

int(0..1) can_encode(mixed a) {
    return stringp(a);
}

string _sprintf(int type) {
    if (type == 'O') {
	if (base) {
	    return sprintf("Serialization.Method(%s)", base);
	} else {
	    return ::_sprintf(type);
	}
    }

    error("wrong type used in sprintf.\n");
}
