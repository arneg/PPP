inherit .Base;

void create() {
    ::create("_float");
}

void raw_to_medium(Serialization.Atom atom) {
	float i;

	if (1 == sscanf(atom->data, "%f", i)) {
	    atom->pdata = i; 
	    return;
	}

    error("cannot decode %O\n", atom);
}

void medium_to_raw(Serialization.Atom atom) {
    atom->data = (string)atom->pdata;
}

void medium_to_done(Serialization.Atom atom) {
    atom->typed_data[this] = atom->pdata;
}

void done_to_medium(Serialization.Atom atom) {
    atom->pdata = atom->typed_data[this];
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

#if 0
// OPTIMIZATION
int(0..1) `==(mixed a) {
    return objectp(a) && object_program(a) == this_program;
}

int __hash() {
    return hash_value(this_program);
}
#endif
