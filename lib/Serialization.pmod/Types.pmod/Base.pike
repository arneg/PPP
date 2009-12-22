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
    if (!low_can_decode(atom)) error("Incompatible types (%s and %s).\n", type, atom->type);

#ifdef ENABLE_THREADS
	object lock = atom->lock();
#endif

    if (!has_index(atom->typed_data, this)) {
		if (atom->has_pdata()) {
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

	mixed ret = atom->typed_data[this];
#ifdef ENABLE_THREADS
	destruct(lock);
#endif
    return ret;
}

string to_raw(Serialization.Atom atom) {
    if (!low_can_decode(atom)) {
		werror("%O\n", this);
		error("Incompatible types (%s and %s).\n", type, atom->type);
    }

#ifdef ENABLE_THREADS
	object lock = atom->lock();
#endif

    if (!stringp(atom->data)) {
		if (atom->has_pdata()) {
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

	mixed ret = atom->data;
#ifdef ENABLE_THREADS
	destruct(lock);
#endif
    return ret;
}

mixed to_medium(Serialization.Atom atom) {
    if (!low_can_decode(atom)) error("Incompatible types (%s and %s).\n", type, atom->type);

#ifdef ENABLE_THREADS
	object lock = atom->lock();
#endif

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

	mixed ret = atom->pdata;
#ifdef ENABLE_THREADS
	destruct(lock);
#endif
    return ret;
}

Serialization.Atom encode(mixed a) {
	if (!can_encode(a)) error("%O: cannot encode %O\n", this, a);

    Serialization.Atom atom = Serialization.Atom(type, 0);
    atom->typed_data[this] = a;
    atom->signature = this;

    return atom;
}

mixed decode(Serialization.Atom atom) {
    return to_done(atom);
}

void raw_to_medium(Serialization.Atom atom) {
    atom->set_pdata(atom->data);
}

void medium_to_raw(Serialization.Atom atom) {
    atom->data = atom->pdata;
}

void medium_to_done(Serialization.Atom atom) { 
    atom->set_typed_data(this, atom->pdata);
}

void done_to_medium(Serialization.Atom atom) {
    atom->set_pdata(atom->typed_data[this]);
}

string render(Serialization.Atom atom) {
	return atom->render();
}
