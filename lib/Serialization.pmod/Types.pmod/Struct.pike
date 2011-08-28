inherit .ListBased;

function|program constructor;
array(string) names;
mapping(string:object) types;

void create(string type, mapping types, void|function|program constructor) { 
    ::create(type);

    this_program::types = types;
    names = sort(indices(types));
    this_program::constructor = constructor;
}

Serialization.Atom encode(mixed o) {
    array a = allocate(sizeof(names));

    foreach (names; int i; string name) {
	if (!o[name]) werror("ignoring %s: %O\n", name, o[name]);
	a[i] = types[name]->encode(o[name])->render();
    }

    return Serialization.Atom(type, a*"");
}

mixed low_decode(object atom, array(Serialization.Atom) a) {
    mapping|object o = constructor ? constructor() : ([]); 

    if (sizeof(names) != sizeof(a)) error("Wrong length. Expected %d. Got %d.", sizeof(names), sizeof(a));

    foreach (a; int i; Serialization.Atom a) {
	if (a->type == "_false") continue;
	//o[names[i]] = types[names[i]]->decode(a);
	`->=(o, names[i], types[names[i]]->decode(a));
    }

    if (callablep(o->atom_init)) o->atom_init();

    return o;
}

int (0..1) can_encode(mixed a) {
    if (programp(constructor)) {
	return Program.inherits(object_program(a), constructor);
    } else if (!constructor && mappingp(a)) {
	return 1;
    } else {
	// TODO: check return type here
	//werror("%O: hit edge case. might not be able to decode %O\n", this, a);
	return 1;
    }
}

string _sprintf(int c) {
    if (c == 'O') {
	return sprintf("Struct(%O)", types);
    }

    return 0;
}
