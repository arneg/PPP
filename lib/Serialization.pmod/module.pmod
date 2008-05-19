//! Checks if a is a subtype of b.
int(0..1) is_subtype_of(string a, string b) {
    if (a == b) return 1;
    if (sizeof(a) < sizeof(b)) return 0;
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
    last = "_";

    for (int i = 0; i < sizeof(t); i++) {
	t[i] = last + t[i];
	last = t[i];
    }

    return t;
}

class Reactor {
    mapping(program:string) program2type = ([]);
    // type -> mapping(program->transform)
    .AbbrevHash handlers = .AbbrevHash();
    .AbbrevHash defaults = .AbbrevHash();

    mixed fission(.Atom a, void|program as, void|object|function with) {
	if (as) { 
	    if (with) {
		if (functionp(with)) {
		    return with(a, as);
		} else {
		    return with->fission(a, as);
		}
	    }

	    array(mapping) t = filter(handlers->all_matches(a->type), has_index, as);

	    if (sizeof(t)) {
		return t[0][as](a, as);
	    }

	    return UNDEFINED;
	}

	// not sure if good!
	// default could be the first transform added for a particular type
	if (as = defaults[type]) {
	    return fission(a, as); 
	}

	return UNDEFINED;
    }

    .Atom fuse(mixed a, void|string type) {

    }
}

class Atom {
    string type;
    mixed data;

    void create(string type, mixed data) {
	this->type = type;
	this->data = data;
    }

    array(string) subtypes() {
	return .subtypes(type);	
    }

    int(0..1) is_subtype_of(this_program a) {
	return .is_subtype_of(type, a->type);
    }

    int(0..1) is_supertype_of(this_program a) {
	return .is_supertype_of(type, a->type);
    }
}

class AtomParser {
    string type;
    int bytes;
    int error = 0;
    string|String.Buffer buf;

    void reset() {
	type = 0;
	bytes = UNDEFINED;
	buf = "";
    }

    int|Atom parse(string data) {
	buf += data;

	if (!type) {
	    if (buf[0] != '_') {
		error = 1;
		return 0;
	    }

	    int pos = search(buf, ' ');

	    if (pos == -1) {
		// we may check here is something is wrong.. potentially
		return 0;
	    }
	    
	    type = buf[0..pos-1];
	    buf = [pos+1..];
	}

	if (!bytes && zero_type(bytes)) {
	    int pos = search(buf, ' ');

	    if (pos == -1) {
		// we could check here if there are chars in the buf
		// that are not numbers.. and return an error 
		return 0;
	    }

	    if (1 != sscanf(buf[0..pos-1], "%d", bytes)) {
		error = 2;
		return 0;
	    }

	    buf = String.Buffer(buf[pos+1..]);
	}

	if (sizeof(buf) == bytes) {
	    object atom = Atom(type, (string)buf);
	    reset();
	    return atom;
	} else if (sizeof(buf) > bytes) {
	    error = 3;
	}

	return 0;
    }
}
