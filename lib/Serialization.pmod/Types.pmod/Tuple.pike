inherit .Base;

array(object) types;
function|program constructor;

void create(string type, int|function|program constructor, object ... types) {
    ::create(type);

    this_program::types = types;
    this_program::constructor = constructor;
}

object|array decode(Serialization.Atom atom) {
    mixed o = atom->get_typed_data(this);

    if (o) return o;

    array(Serialization.Atom) list = Serialization.parse_atoms(atom->data);
    if (sizeof(list) != sizeof(types))
	error("Tuple has wrong length.");
    o = allocate(sizeof(types));
    foreach (list; int i; Serialization.Atom a) {
	o[i] = types[i]->decode(a);
    }
    if (constructor) o = constructor(@o);
    atom->set_typed_data(this, o);
    return o;
}

Serialization.StringBuilder render(object|array list, Serialization.StringBuilder buf) {
    int|array node = buf->add();
    int length = buf->length();

    if (sizeof(list) != sizeof(types))
	error("Tuple has wrong length.");

    list = (array)list;

    foreach (list; int i; mixed o) {
	types[i]->render(o, buf);
    }

    buf->set_node(node, sprintf("%s %d ", type, buf->length() - length));
    return buf;
}

string render_payload(Serialization.Atom atom) {
    array|object list = atom->get_typed_data(this);
    if (!list) error("Using broken atom: %O\n", atom);
    list = (array)list;
    if (sizeof(list) != sizeof(types))
	error("Tuple has wrong length.");
    Serialization.StringBuilder buf = Serialization.StringBuilder();


    foreach (list; int i; mixed element) {
	types[i]->render(element, buf);
    }

    return buf->get();
}

int (0..1) can_encode(mixed a) {
	if (!constructor) return arrayp(a);
	if (objectp(a) && programp(constructor)) {
	    return Program.inherits(object_program(a), constructor);
	} else {
	    // TODO: check return type here
	    werror("%O: hit edge case. might not be able to decode %O\n", this, a);
	    return 0;
	}
}


string _sprintf(int c) {
    if (c == 'O') {
		return sprintf("Tuple(%O)", types);
    }

    return 0;
}
