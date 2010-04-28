object vars;

void create(mapping params) {
	vars = Serialization.Types.gen_vars(params);
}

int(0..1) can_encode(mixed o) { return vars->can_encode(o); }
int(0..1) can_decode(Serialization.Atom atom) { return vars->can_decode(atom); }
Serialization.Atom encode(mixed o) { return vars->encode(o); }
mixed decode(Serialization.Atom atom) { return vars->decode(atom); }
string render_payload(Serialization.Atom atom) { return vars->render_payload(atom); }
Serialization.StringBuilder render(mixed o, Serialization.StringBuilder buf) { return vars->render(o, buf); }

string _sprintf(int c) {
    if (c == 'O') {
		return sprintf("%O", vars);
    }

    return 0;
}
