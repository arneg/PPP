inherit .Base;

function|program constructor;
array(string) names;
mapping(string:object) types;

void create(string type, mapping types, void|function|program constructor) { 
    ::create(type);

    this_program::types = types;
    names = sort(indices(types));
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
    mapping|object o = constructor ? constructor() : ([]); 

    foreach (atom->pdata; int i; Serialization.Atom a) {
	o[names[i]] = types[names[i]]->decode(a);
    }

    atom->set_typed_data(this, o);
}

int (0..1) low_can_encode(mixed a) {
    if (programp(constructor)) {
	return Program.inherits(object_program(a), constructor);
    } else if (!constructor && mappingp(a)) {
	return 1;
    } else {
	// TODO: check return type here
	werror("%O: hit edge case. might not be able to decode %O\n", this, a);
	return 1;
    }
}

string _sprintf(int c) {
    if (c == 'O') {
	return sprintf("Struct(%O)", types);
    }

    return 0;
}
