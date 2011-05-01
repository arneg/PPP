inherit .Base;

mixed low_decode(Serialization.Atom a, array(Serialization.Atom) b) { error("DO NOT USE ME!\n"); }

mixed decode(Serialization.Atom a) {
    return low_decode(a, Serialization.parse_atoms(a->data));
}
