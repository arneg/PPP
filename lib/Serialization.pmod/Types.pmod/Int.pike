inherit .Base;

void create() {
    ::create("_integer");
}

int decode(Serialization.Atom a) {
    
    to_done(a);
    return a->typed_data[this];


}

Serialization.Atom encode(Serialization.Atom|int i) {
    if (low_can_encode(i)) return i;
    if (!intp(i)) error("cannot encode non-integer %O\n", i);

    Serialization.Atom a = Serialization.Atom("_integer", 0);
    a->typed_data[this] = i;
    a->signature = this;

    return a;
}

void to_done(Serialization.Atom atom) {
    if (has_index(atom->typed_data, this)) return;
    if (!stringp(atom->data)) error("No raw state in %O.\n", atom);

    if (can_decode(atom)) {
	int i;
	if (1 == sscanf(atom->data, "%d", i)) {
	    atom->typed_data[this] = i; 
	    return;
	}
    }

    error("cannot decode %O\n", atom);
}

void to_raw(Serialization.Atom atom) {
    if (stringp(atom->data)) return;
    if (!has_index(atom->typed_data, this)) error("No done state.\n");

    atom->data = (string)atom->typed_data[this];
}

int(0..1) can_encode(mixed a) {
    if (low_can_encode(a)) return 1;
    return intp(a);
}

string _sprintf(int c) {
    if (c == 'O') {
	return "Int()";
    }

    return 0;
}

int(0..1) `==(mixed a) {
    return objectp(a) && object_program(a) == this_program;
}

int __hash() {
    return hash_value(this_program);
}
