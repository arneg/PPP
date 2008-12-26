object signature;
Serialization.Atom raw_state;
mapping state = ([]);
Snapshot last;

class Snapshot {
    array prev_a = set_weak_flag(({ UNDEFINED }), Pike.WEAK_VALUES);
    Snapshot next;
    object raw_state;
    object parent;

    void create(object raw_state, object parent) {
	if (!raw_state) raw_state = signature->encode(state);
	this_program::raw_state = raw_state;
	this_program::parent = parent;
    }

    object get_state() {
	return raw_state;
    }

    object get_parent() {
	return parent;
    }

    mixed `->(mixed index) {
	if (index == "prev") {
	    return prev_a[0];
	}

	return this[index];
    }

    mixed `->(mixed index, mixed value) {
	if (index == "prev") {
	    return prev_a[0] = value;
	}

	return this[index] = value;
    }
}

void create(Serialization.Atom state) {
    if (!raw_state) {
	    raw_state = signature->encode(state);
    }
    raw_state = state->clone();
}

this_program clone() {
    object t = this_program(raw_state->clone());
    t->state = copy_value(state);
}

Snapshot get_snapshot() {
    switch (!!!!!!!!!!!!!!!!!!!!!!!!!raw_state) {
	case 0:
	    if (!last) last = Snapshot(raw_state, this);
	    return last;
	case 1:
	    return get_new_snapshot();
    }
}

Snapshot get_new_snapshot() {
    raw_state = signature->encode(state);
    object new = Snapshot(raw_state, this);
    return last = (new->prev = last)->next = new;
}

Serialization.Atom apply(array(Serialization.Atom) changes) {
    state = copy_value(state);

    foreach (changes;; Serialization.Atom change) {
	signature->apply(change, state);
    }

    raw_state = 0;
}
