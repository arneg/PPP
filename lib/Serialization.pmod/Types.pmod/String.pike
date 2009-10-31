inherit .Base;

void create() {
    ::create("_string");
}

void raw_to_medium(Serialization.Atom atom) {
    atom->set_pdata(utf8_to_string(atom->data));
}

void medium_to_raw(Serialization.Atom atom) {
    atom->data = string_to_utf8(atom->pdata);
}

int(0..1) can_encode(mixed a) {
    return stringp(a);
}

string _sprintf(int c) {
    if (c == 'O') {
		return "String()";
    }

    return 0;
}
