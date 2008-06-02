constant STRING  = 1;
constant ARRAY   = 2;
constant MAPPING = 3;
constant INT     = 4;
constant FLOAT   = 5;

int|program to_type(mixed a) {
    if (objectp(a)) return object_program(a);
    if (stringp(a)) return .STRING;
    if (arrayp(a)) return .ARRAY;
    if (mappingp(a)) return .MAPPING;
    if (intp(a)) return .INT;
    if (floatp(a)) return .FLOAT;

    return 0;
}

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
    t = (type / "_")[1..];
    last = "";

    for (int i = 0; i < sizeof(t); i++) {
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

// we want utf8 as default?! 
.Atom encode_string(string s, string type, object reactor) {
    return .Atom(type, string_to_utf8(s));
}
string decode_string(.Atom a, int|program ptype, object reactor) {
    if (ptype != .STRING) return UNDEFINED;
    
    return utf8_to_string(a->data);
}

int decode_int(.Atom a, int|program ptype, object reactor) {
    int i;

    if (ptype != .INT) return UNDEFINED;

    if (1 == sscanf("%d", a->data, i)) {
	return i;
    }

    return UNDEFINED;
}

.Atom encode_int(int i, string type, object reactor) {
    return .Atom(type, sprintf("%d", i));
}

// returns a mapping of atoms if no type2program has been specified
mapping decode_atom_mapping(.Atom a, int|program ptype, object reactor, void|mapping(string:int|program) type2program) {
    if (ptype != .MAPPING) return UNDEFINED;
    object parser = .AtomParser();
    parser->feed(a->data);
    
    array(.Atom) list = parser->parse_all();
    if (sizeof(list) & 1) return UNDEFINED;

    if (mappingp(type2program) && sizeof(type2program)) foreach (list;int i;.Atom a) {
	if (has_index(type2program, a->type)) {
	    list[i] = reactor->fission(a, type2program[a->type]);
	}
    }

    return aggregate_mapping(@list);
}

.Atom encode_atom_mapping(mapping(.Atom:.Atom) m, string type, object reactor, void|mapping(int|program:string) program2type) {
    String.Buffer buf = String.Buffer();
    
    foreach (m;.Atom key; .Atom value) {
	.render_atom(key, buf);
	.render_atom(value, buf);
    }

    return .Atom(type, (string)buf);
}

object get_default_reactor() {
    object reactor = .Reactor();
    // these hurt our inheritance rules.. examples!
    reactor->register_fuse("_string_utf8", .STRING, .encode_string);
    reactor->register_fission("_string_utf8", .STRING, .decode_string);

    reactor->register_fuse("_integer", .INT, .encode_int);
    reactor->register_fission("_integer", .INT, .decode_int);

    return reactor;
}
