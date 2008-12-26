object signature;
Serialization.Atom raw_state;
mapping state = ([]);

void create(Serialization.Atom state) {
    raw_state = state->clone();
}

this_program clone() {
    object t = this_program(raw_state->clone());
    t->state = copy_value(state);
}

Serialization.Atom apply(array(Serialization.Atom) changes) {
    state = copy_value(state);

    foreach (changes;; Serialization.Atom change) {
	signature->apply(change, state);
    }

    raw_state = 0;
}

Serialization.Atom snapshot() {
    if (!raw_state) raw_state = signature->encode(state);
    return raw_state;
}
