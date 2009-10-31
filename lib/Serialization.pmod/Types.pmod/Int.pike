inherit .Base;

void create() {
    ::create("_integer");
}

void raw_to_medium(Serialization.Atom atom) {
	int i;

	if (1 == sscanf(atom->data, "%d", i)) {
	    atom->set_pdata(i);
		return;
	}

    error("cannot decode %O\n", atom);
}

void medium_to_raw(Serialization.Atom atom) {
    atom->data = (string)atom->pdata;
}

int(0..1) can_encode(mixed a) {
    return intp(a);
}

string _sprintf(int c) {
    if (c == 'O') {
		return "Int()";
    }

    return 0;
}
