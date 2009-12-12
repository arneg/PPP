string type = "_mmp";
object dtype, vtype;

void create(object dtype, object vtype) {
	this_program::dtype = dtype;
	this_program::vtype = vtype;
}

MMP.Packet decode(Serialization.Atom atom) {
	if (has_index(atom->typed_data, this)) return atom->typed_data[this];
	array(Serialization.Atom) list = Serialization.parse_atoms(atom->data);	

	if (sizeof(list) != 2) {
		error("Malformed Packet atom: %O\n", atom);
	}

	MMP.Packet p = MMP.Packet(dtype->decode(list[0]), vtype->decode(list[1]));
	//p->set_atom(atom);
	atom->set_typed_data(this, p);
	return p;	
}

Serialization.Atom encode(MMP.Packet p) {
	if (p->atom) return p->atom;

	Serialization.Atom a = Serialization.Atom("_mmp", 0);
	a->set_typed_data(this, p);
	
	p->set_atom(atom);
	return a;
}

void to_raw(Serialization.Atom a) {
	MMP.Packet p = a->typed_data[this];
	a->data = (dtype->encode(p->data)->render() + vtype->encode(p->vars)->render());
}

string _sprintf(int c) {
    if (c == 'O') {
		return sprintf("Packet(%O, %O)", dtype, vtype);
    }

    return 0;
}

int(0..1) can_encode(mixed o) {
	return Program.inherits(object_program(o), MMP.Packet);
}

int(0..1) can_decode(Serialization.Atom atom) {
	return atom->type == "_mmp";
}
