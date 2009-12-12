Serialization.Atom atom;

void set_atom(Serialization.Atom atom) {
	this_program::atom = atom;
	atom->condense();
}
