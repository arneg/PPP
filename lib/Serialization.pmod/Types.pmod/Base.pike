string type;

void create(string type) {
    this_program::type = type;
}

int(0..1) is_subtype_of(object a) {
    return Serialization.is_subtype_of(type, a->type);
}

int(0..1) is_supertype_of(object a) {
    return Serialization.is_supertype_of(type, a->type);
}

int(0..1) low_can_decode(mixed a) {
    if (object_program(a) != Serialization.Atom) return 0;
    return is_subtype_of(a);
}

int (0..1) low_can_encode(mixed a) {
    return 0;
}

int(0..1) can_encode(mixed a);

int(0..1) can_decode(Serialization.Atom atom) {
    if (low_can_decode(atom)) {
		mixed err = catch { to_done(atom); };
		return !err;
    }
    return 0;
}

string _sprintf(int t) {
    if (t == 'O') {
		return sprintf("Serialization.Type(%s)", type);
    }

    return 0;
}

mixed to_done(Serialization.Atom atom) {
    if (!low_can_decode(atom)) error("Incompatible types.\n");

    if (!has_index(atom->typed_data, this)) {
		if (atom->pdata) {
			medium_to_done(atom);
		} else if (sizeof(atom->typed_data)) {
			[object signature, mixed a] = random(atom->typed_data);
			signature->done_to_medium(atom);
			medium_to_done(atom);
		} else if (stringp(atom->data)) {
			raw_to_medium(atom);
			medium_to_done(atom);
		} else {
			error("This atom is completely without information: %O.\n", atom);
		}
    }

    return atom->typed_data[this];
}

string to_raw(Serialization.Atom atom) {
    if (!low_can_decode(atom)) {
		werror("%O\n", this);
		error("Incompatible types %s and %s.\n", type, atom->type);
    }

    if (!stringp(atom->data)) {
		if (atom->pdata) {
			medium_to_raw(atom);
		} else if (has_index(atom->typed_data, this)) {
			done_to_medium(atom);
			medium_to_raw(atom);
		} else if (sizeof(atom->typed_data)) {
			[object signature, mixed a] = random(atom->typed_data);
			signature->done_to_medium(atom);
			medium_to_raw(atom);
		} else {
			error("This atom is completely without information: %O.\n", atom);
		}
    }

    return atom->data;
}

mixed to_medium(Serialization.Atom atom) {
    if (!low_can_decode(atom)) error("Incompatible types.\n");

    if (!atom->has_pdata()) {
		if (has_index(atom->typed_data, this)) {
			done_to_medium(atom);
		} else if (sizeof(atom->typed_data)) {
			[object signature, mixed a] = random(atom->typed_data);
			signature->done_to_medium(atom);
		} else if (stringp(atom->data)) {
			raw_to_medium(atom);
		} else {
			error("This atom is completely without information: %O.\n", atom);
		}
    }

    return atom->pdata;
}

Serialization.Atom encode(mixed a) {
//    if (!can_encode(a)) error("Cannot encode %O.\n", a);

    Serialization.Atom atom = Serialization.Atom(type, 0);
    atom->typed_data[this] = a;
    atom->signature = this;

    return atom;
}

mixed decode(Serialization.Atom atom) {
    to_done(atom);
    return atom->typed_data[this];
}

void raw_to_medium(Serialization.Atom atom) {
    atom->pdata = atom->data;
}

void medium_to_raw(Serialization.Atom atom) {
    atom->data = atom->pdata;
}

void medium_to_done(Serialization.Atom atom) { 
    atom->typed_data[this] = atom->pdata;
}

void done_to_medium(Serialization.Atom atom) {
    atom->pdata = atom->typed_data[this];
}

string render(Serialization.Atom atom) {
    to_raw(atom);
    return sprintf("%s %d %s", atom->action ? atom->type+":"+atom->action : atom->type, sizeof(atom->data), atom->data); 
}
