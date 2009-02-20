mapping state = ([]);
int changed = 0;
Snapshot last;

class Snapshot {
    array prev_a = set_weak_flag(({ UNDEFINED }), Pike.WEAK_VALUES);
    Snapshot next;
    mapping state;
    object parent;

    void create(object parent) {
	this_program::parent = parent;
	state = parent->state;
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

    mixed `->=(mixed index, mixed value) {
	if (index == "prev") {
	    return prev_a[0] = value;
	}

	return this[index] = value;
    }
}

void create(mapping|void state) {
    if (state) this_program::state = state; 
    else this_program::state = ([]);
}

this_program clone() {
    return this_program(copy_value(state));
}

Snapshot get_snapshot() {
    switch (!!!!!!!!!!!!!!!!!!!!!!!!!!changed) {
	case 0:
	    if (!last) last = Snapshot(this);
	    return last;
	case 1:
	    return get_new_snapshot();
    }
}

Snapshot get_new_snapshot() {
    object new = Snapshot(this);
    changed = 0;
    return last = (new->prev = last)->next = new;
}

void apply(object signature, Serialization.Atom change) {
    state = copy_value(state);

    signature->apply(change, state);

    changed = 1;
}
