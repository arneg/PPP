inherit .Base;

array(object) types;
function|program constructor;

void create(string type, function|program constructor, object ... types) {
    ::create(type);

    this_program::types = types;
    this_program::constructor = constructor;
}

void raw_to_medium(Serialization.Atom atom) {
    atom->set_pdata(Serialization.parse_atoms(atom->data));
}

void medium_to_raw(Serialization.Atom atom) {
    String.Buffer buf = String.Buffer();

    foreach (atom->pdata;;Serialization.Atom a) {
		buf = a->render(buf);	
    }

    atom->data = (string)buf;
}

void medium_to_done(Serialization.Atom atom) {
	array(object) t = allocate(sizeof(atom->pdata));

	foreach (atom->pdata; int i; Serialization.Atom a) {
		t[i] = types[i]->decode(a);
	}

	atom->set_typed_data(this, constructor(@t));
}

int (0..1) can_encode(mixed a) {
	if (programp(constructor)) {
		return Program.inherits(object_program(a), constructor);
	} else {
		// TODO: check return type here
		werror("%O: hit edge case. might not be able to decode %O\n", this, a);
		return 1;
	}
}

string _sprintf(int c) {
    if (c == 'O') {
		return sprintf("Tuple(%O)", types);
    }

    return 0;
}
