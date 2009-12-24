string type = "_float";


float decode(Serialization.Atom a) {
	return (float)a->data;
}
Serialization.Atom encode(float f) {
	return Serialization.Atom(type, sprintf("%g", f));
}
int(0..1) can_decode(Serialization.Atom a) {
	return a->type == type;
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

