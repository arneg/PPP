inherit .Base;

array(object) types;
function|program constructor;

void create(string type, function|program constructor, object ... types) {
    ::create(type);

    this_program::types = types;
	this_program::constructor = constructor;
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

	array(object) t = allocate(sizeof(atom->pdata));

	foreach (atom->pdata; int i; Serialization.Atom a) {
		t[i] = types[i]->decode(a);
	}

	atom->typed_data[this] = constructor(@t);
}

int (0..1) low_can_encode(mixed a) {
    return object_program(a) == constructor;
}

string _sprintf(int c) {
    if (c == 'O') {
		return sprintf("Struct(%O)", types);
    }

    return 0;
}
