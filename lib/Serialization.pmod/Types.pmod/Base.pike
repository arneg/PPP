string type;


int(0..1) can_encode(Serialization.Atom atom);
int(0..1) can_decode(Serialization.Atom atom) {
    return type == atom->type;
}

string _sprintf(int t) {
    if (t == 'O') {
		return sprintf("Serialization.Type(%s)", type);
    }

    return 0;
}

Serialization.Atom encode(mixed a) {
    if (!can_encode(a)) error("%O: cannot encode %O\n", this, a);

    Serialization.Atom atom = Serialization.Atom(type, 0);
    atom->typed_data[this] = a;
    atom->signature = this;

    return atom;
}
