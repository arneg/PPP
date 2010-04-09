string type = "_mmp";
object dtype, vtype;

void create(object dtype, object vtype) {
	this_program::dtype = dtype;
	this_program::vtype = vtype;
}

MMP.Packet decode(Serialization.Atom atom) {
	MMP.Packet p;
	array(Serialization.Atom) list = Serialization.parse_atoms(atom->data);	

	if (sizeof(list) != 2) {
		error("Malformed Packet atom: %O\n", atom);
	}

	p = MMP.Packet(dtype->decode(list[0]), vtype->decode(list[1]));
	//atom->set_typed_data(this, p);
	p->set_atom(atom);
	return p;
}

Serialization.Atom encode(MMP.Packet p) {
	if (p->atom) return p->atom;

	Serialization.Atom a = Serialization.Atom("_mmp", 0);
	a->set_typed_data(this, p);
	p->set_atom(a);
	a->condense();

	return a;
}

MMP.Utils.StringBuilder buffer = MMP.Utils.StringBuilder();

string|MMP.Utils.StringBuilder render(MMP.Packet p, void|MMP.Utils.StringBuilder buf) {
    int nbuf = !buf;

    if (nbuf && p->raw) {
	return p->raw;
    }

    if (p->atom) {
	    p->atom->condense();
	    if (nbuf) return p->atom->render();
	    else return p->atom->render(buf);
    }

    if (nbuf) buf = buffer;

    int|array node = buf->add();
    int length = buf->length();

    dtype->render(p->data, buf);
    vtype->render(p->vars, buf);

    buf->set_node(node, sprintf("%s %d ", type, buf->length() - length));

    if (nbuf) {
	p->raw = MMP.Utils.Cloak(buf->get());
	return p->raw;
    }
    return buf;
}

string render_payload(Serialization.Atom atom) {
    MMP.Packet p = atom->get_typed_data(this);

    if (!p) error("Rendering empty atom: %O\n", atom);
    MMP.Utils.StringBuilder buf = buffer;

    dtype->render(p->data, buf);
    vtype->render(p->vars, buf);

    return buf->get();
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
