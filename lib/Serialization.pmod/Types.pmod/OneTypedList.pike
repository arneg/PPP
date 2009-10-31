inherit .Base;
object etype;
object itype = Serialization.Types.Int();

void create(object type) {
    ::create("_list");

	if (!objectp(type)) error("Bad type %O\n", type);
    
    this_program::etype = type;
}

void raw_to_medium(Serialization.Atom atom) {
    atom->pdata = Serialization.parse_atoms(atom->data);
}

void medium_to_raw(Serialization.Atom atom) {
    if (!arrayp(atom->pdata)) error("broken pdata: %O\n", atom->pdata);
    String.Buffer buf = String.Buffer();

    foreach (atom->pdata;;Serialization.Atom a) {
		buf = a->render(buf);	
    }

    atom->data = (string)buf;
}

void medium_to_done(Serialization.Atom atom) {
    if (!arrayp(atom->pdata)) error("broken pdata: %O\n", atom->pdata);
    atom->typed_data[this] = map(atom->pdata, etype->decode);
}

void done_to_medium(Serialization.Atom atom) {
    if (!arrayp(atom->typed_data[this])) error("broken typed_data: %O\n", atom->typed_data[this]);
    atom->pdata = map(atom->typed_data[this], etype->encode);
}

int (0..1) low_can_encode(mixed a) {
    return arrayp(a);
}

int(0..1) can_encode(mixed a) {
    if (low_can_decode(a)) return 1;
    if (!arrayp(a)) return 0;

    foreach (a;;mixed i) {
	if (!etype->can_encode(i)) {
	    return 0;
	}
    }

    return 1;
}

string _sprintf(int c) {
    if (c == 'O') {
		return sprintf("List(%O)", etype);
    }

    return 0;
}
