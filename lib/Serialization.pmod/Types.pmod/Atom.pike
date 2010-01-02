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

mixed decode(Serialization.Atom atom) {
	return atom;
}

mixed encode(Serialization.Atom atom) {
	return atom;
}

MMP.Utils.StringBuilder render(Serialization.Atom atom, MMP.Utils.StringBuilder buf) {
    return atom->render(buf);
}
