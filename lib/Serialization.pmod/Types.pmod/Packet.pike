inherit .Struct;

void create(object dtype, object vtype) {
	::create("_mmp", MMP.Packet, dtype, vtype);
}

void done_to_medium(Serialization.Atom atom) {
	object p = atom->typed_data[this];

	if (!p) error("No typed data available.\n");

	atom->set_pdata(({ types[0]->encode(p->data), types[1]->encode(p->vars) }));
}

string _sprintf(int c) {
    if (c == 'O') {
		return sprintf("Packet(%O)", types);
    }

    return 0;
}

int(0..1) can_encode(mixed o) {
	return Program.inherits(object_program(o), MMP.Packet);
}
