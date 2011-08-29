string type;

int(0..1) can_encode(Serialization.Atom atom);
int(0..1) can_decode(Serialization.Atom atom) {
    return type == atom->type;
}

void create(string type) {
    this_program::type = type;
}

string _sprintf(int t) {
    if (t == 'O') {
		return sprintf("Serialization.Type(%s)", type||sprintf("%O", this_program));
    }

    return 0;
}

Serialization.Atom encode(mixed a) {
    if (!can_encode(a)) error("%O: cannot encode %O\n", this, a);

    Serialization.Atom atom = Serialization.Atom(type, 0);
    atom->set_typed_data(this, a);

    return atom;
}

Serialization.StringBuilder render(mixed t, Serialization.StringBuilder buf) {
    return encode(t)->render(buf);
}

object `|(object o) {
    if (Program.inherits(object_program(o), Serialization.Types.Or)) {
	return Serialization.Types.Or(this, @o->types);
    } else if (Program.inherits(object_program(o), Serialization.Types.Base)) {
	return Serialization.Types.Or(this, o);
    }
    error("cannot or this %O", o);
}
