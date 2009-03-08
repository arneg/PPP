int (0..1) can_encode(mixed a) {
    return objectp(a) && (object_program(a) == Serialization.Atom);
}

int (0..1) can_decode(mixed a) {
    return can_encode(a);
}

string _sprintf(int type) {
    if (type == 'O') {
	return "Serialization.AnyAtom()";
    }

    return 0;
}
