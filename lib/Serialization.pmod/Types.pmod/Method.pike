inherit .Base;

string base;

#define OK(x)		(stringp(x) && String.width(x) == 8 && (!base || has_prefix((x), base)))
#define CHECK(x)	do { if (!OK(x)) error("%O is not a submethod of '%s'.\n", (x), base); } while(0);

void create(void|string base) {
    ::create("_method");

    if (base) this_program::base = base;
}

int(0..1) can_encode(mixed a) {
    return OK(a);
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
