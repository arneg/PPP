object etype;
string type = "_type";

void create(object type) {
    if (!objectp(type)) error("Bad type %O\n", type);
    
    this_program::etype = type;
}

Serialization.Atom encode(array list) {
    Serialization.Atom a = Serialization.Atom(type, 0);
    a->set_typed_data(this, list);
    return a;
}

array decode(Serialization.Atom atom) {
    mixed o = atom->get_typed_data(this);

    if (o) return o;
    
    array(Serialization.Atom) list = Serialization.parse_atoms(atom->data);
    foreach (list; int i; Serialization.Atom a) {
	list[i] = etype->decode(a);
    }
    atom->set_typed_data(this, list);
    return list;
}

MMP.Utils.StringBuilder render(array list, MMP.Utils.StringBuilder buf) {
    array node = buf->add();
	int length = buf->length();

    foreach (list; int i; mixed o) {
		etype->render(o, buf);
    }

    buf->set_node(node, sprintf("%s %d ", type, buf->length() - length));
    return buf;
}

string render_payload(Serialization.Atom atom) {
    array list = atom->get_typed_data(this);
    if (!list) error("Using broken atom: %O\n", atom);
    MMP.Utils.StringBuilder buf = MMP.Utils.StringBuilder();

    foreach (list; int i; mixed element) {
	etype->render(element, buf);
    }

    return buf->get();
}

int (0..1) can_encode(mixed a) {
    return arrayp(a);
    // TODO: think about recursive deep check here
}

string _sprintf(int c) {
    if (c == 'O') {
	return sprintf("List(%O)", etype);
    }

    return 0;
}
