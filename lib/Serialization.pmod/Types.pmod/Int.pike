inherit .Base;

void create() {
    ::create("_integer");
}

int decode(Serialization.Atom a) {
    
    if (has_index(a->typed_data, this)) return a->typed_data[this];

    if (can_decode(a)) {
	int i;
	if (1 == sscanf(a->data, "%d", i)) {
	    return i; 
	}
    }

    error("cannot decode %O\n", a);
}

Serialization.Atom encode(Serialization.Atom|int i) {
    if (low_can_encode(i)) return i;
    if (!intp(i)) error("cannot encode non-integer %O\n", i);

    Serialization.Atom a = Serialization.Atom("_integer", 0);
    a->typed_data[this] = i;
    a->signature = this;

    return a;
}

string render(int i) { 
    return (string)i;
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
