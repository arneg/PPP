string base;

#define OK(x)		(stringp(x) && String.width(x) == 8 && (!base || has_prefix((x), base)))
#define CHECK(x)	do { if (!OK(x)) error("%O is not a submethod of '%s'.\n", (x), base); } while(0);

void create(void|string base) {
    ::create("_method");

    if (base) this_program::base = base || "_";
}

int(0..1) can_encode(mixed a) {
    return OK(a);
}

int(0..1) can_decode(Serialization.Atom a) {
	return a->type == "_method";
}

string decode(Serialization.Atom a) {
	return a->data;
}

Serialization.Atom encode(string s) {
	CHECK(s);
	return Serialization.Atom("_method", s);
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
