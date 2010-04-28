inherit Serialization.Types.Int;

void create() {
	type = "_time";
}

Serialization.Atom encode(mixed o) {
	return ::encode(intp(o) ? o : o->unix_time());
}

Calendar.TimeRange decode(Serialization.Atom atom) {
	return Calendar.Second("unix", ::decode(atom));
}

int(0..1) can_encode(mixed o) {
	return intp(o) || Program.inherits(object_program(o), Calendar.TimeRange);
}

Serialization.StringBuilder render(mixed o, Serialization.StringBuilder buf) {
    return ::render(intp(o) ? o : o->unix_time(), buf);
}
