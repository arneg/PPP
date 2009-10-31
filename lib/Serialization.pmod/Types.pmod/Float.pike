inherit .Base;

void create() {
    ::create("_float");
}

void raw_to_medium(Serialization.Atom atom) {
	float i;

	if (1 == sscanf(atom->data, "%f", i)) {
	    atom->set_pdata(i);
	    return;
	}

    error("cannot decode %O\n", atom);
}

void medium_to_raw(Serialization.Atom atom) {
    atom->data = (string)atom->pdata;
}

int(0..1) can_encode(mixed a) {
    return floatp(a);
}

string _sprintf(int c) {
    if (c == 'O') {
		return "Float()";
    }

    return 0;
}

