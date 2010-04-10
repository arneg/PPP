object default_type_cache = Serialization.TypeCache();

//! Checks if a is a subtype of b.
int(0..1) is_subtype_of(string a, string b) {
    if (a == b) return 1;
    if (sizeof(a) <= sizeof(b)) return 0;
    if (has_prefix(a, b) && a[sizeof(b)] == '_') return 1;
    return 0;
}


//! Checks if a is a supertype of b.
int(0..1) is_supertype_of(string a, string b) {
    return is_subtype_of(b, a);
}

int(0..1) is_type(string type) {
    return type[0] == '_';
}

array(string) subtypes(string type) {
    array(string) t;
    string last;

    if (!is_type(type)) return 0;
    t = (type / "_");
	t[0] = "_";
    last = "";

    for (int i = 1; i < sizeof(t); i++) {
		t[i] = last + "_" + t[i];
		last = t[i];
    }

    return t;
}

string|void render_atom(.Atom a, void|String.Buffer buf) {
	if (!buf) {
		return sprintf("%s %d %s", a->type, sizeof(a->data), a->data);
	} else {
		buf->add(sprintf("%s %d %s", a->type, sizeof(a->data), a->data));
	}
}

array(.Atom) parse_atoms(string s) {
    array(.Atom) ret = ({});

	int bytes;
	string type;
	string ts;

    while (sizeof(s) && 3 == sscanf(s, "%[_a-zA-Z] %d %s", type, bytes, ts)) {
		if (sizeof(s) < bytes) error("Cannot parse this.");

		.Atom t = .Atom(type, ts[0..bytes-1]);
		t->done = s[0..bytes-1 + sizeof(s) - sizeof(ts)];
		s = ts;

		if (sizeof(s) > bytes) s = s[bytes..];
		else s = "";

		ret += ({ t });
    }

	if (sizeof(s) > bytes) error("Something left.\n");

    return ret;
}
