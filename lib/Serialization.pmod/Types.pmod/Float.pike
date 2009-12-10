string type = "_float";


float decode(Serialization.Atom a) {
	return (float)a->data;
}
Serialization.Atom encode(float f) {
	return Serialization.Atom("_float", sprintf("%g", f));
}
int(0..1) can_decode(Serialization.Atom a) {
	return a->type == "_float";
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

