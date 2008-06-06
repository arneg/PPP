inherit .Base;

void create() {
    ::create("_integer");
}

int decode(Serialization.Atom a) {
    if (can_decode(a)) {
	int i;
	if (1 == sscanf("%d", a->data, i)) {
	    return i; 
	}
    }

    throw(({}));
}

Serialization.Atom encode(int i) {
    if (intp(i)) {
	object a = Serialization.Atom("_uniform", (string)i);
	a->parsed = 1;
	a->pdata = i;

	return a;
    }

    throw(({}));
}

int(0..1) can_encode(mixed a) {
    return intp(a);
}
