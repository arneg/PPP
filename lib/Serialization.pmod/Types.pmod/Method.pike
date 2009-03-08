inherit .Base;

string base;

#define OK(x)		(stringp(s) && String.width(s) == 8 && (!base || has_prefix((x), base)))
#define CHECK(x)	do { if (!OK(x)) error("%O is not a submethod of '%s'.\n", (x), base); } while(0);

void create(void|string base) {
    ::create("_method");

    if (base) this_program::base = base;
}

int(0..1) can_encode(mixed a) {
    return OK(a);
}

void raw_to_medium(Serialization.atom atom) {
    CHECK(atom->data);
    atom->pdata = data;
}

void medium_to_raw(Serialization.Atom atom) { 
    CHECK(atom->pdata);
    atom->data = atom->pdata;
}

void medium_to_done(Serialization.Atom atom) { 
    CHECK(atom->pdata);
    atom->typed_data[this] = atom->pdata;
}

void done_to_medium(Serialization.Atom atom) {
    CHECK(atom->typed_data[this]);
    atom->pdata = atom->typed_data[this];
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
