inherit .Base;

object hash = Serialization.AbbrevHash();
object ohash = Serialization.AbbrevHash();
object str;

void create(object str, void|mapping(string:object) mandatory, void|mapping(string:object) rest) {
    ::create("_mapping");
    
    if (mandatory) {
	hash->fill(mandatory);
    }

    if (rest) {
	ohash->fill(rest);
    }
    
    this_program::str = str;
}

void low_decode(Serialization.Atom a) {
    if (a->parsed) {
	return 0;
    }

    object parser = Serialization.AtomParser();

    parser->feed(a->data);
    array(Serialization.Atom) list = parser->parse_all();

    if (sizeof(list) & 1) throw(({}));

    // we keep the array.. more convenient
    a->pdata = list;
    a->parsed = 1;
}

mapping decode(Serialization.Atom a) {
    if (!low_can_decode(a)) throw(({}));

    if (!a->parsed) low_decode(a);

    mapping m = ([]);
    array(Serialization.Atom) list = a->pdata;
    int needed = sizeof(hash);

    for (int i = 0; i < sizeof(list); i += 2) {
	string key;
	mixed value;

	if (str->can_decode(list[i])) {
	    key = str->decode(list[i]);
	    string index = hash->find_index(key);

	    if (index) {
		object type = hash->m[index];

		if (type->can_decode(list[i+1])) {
		    value = type->decode(list[i+1]);
		} else {
		    throw(({ "evil, cannot decode value!\n", backtrace() }));
		}

		if (!has_index(m, index)) 
		    needed--;
		m[index] = value;
		continue;
	    }

	    index = ohash->find_index(key);

	    if (index) { // we dont complain about junk. could be an extension to the packet.
		object type = hash->m[index];

		if (type->can_decode(list[i+1])) {
		    value = type->decode(list[i+1]);
		} else {
		    throw(({ "evil, cannot decode value!\n", backtrace() }));
		}

		m[index] = value;
	    } 

	} else {
	    throw(({ "Could not decode key!\n", backtrace() }));
	}
    }

    if (needed) {
	throw(({ "Mandatory variables missing.\n", backtrace()  }));
    }

    return m;
}

Serialization.Atom encode(mapping m) {
    String.Buffer buf = String.Buffer();
    
    // we want late rendering...!!!
    // but that should probably be done when actually
    // putting stuff on the wire/hdd

    multiset needed = mkmultiset(indices(hash));

    foreach (m; string key; mixed value) {

	string index = hash->find_index(key);

	if (!str->can_encode(key)) {
	    throw(({ "Cannot encode key!\n", backtrace() }));
	}

	if (index && needed[index]) {
	    object type = hash->m[index];

	    if (type->can_encode(value)) {
		Serialization.render_atom(str->encode(key), buf);
		Serialization.render_atom(type->encode(value), buf);
	    } else {
		throw(({ "Could not encode mapping value!\n", backtrace() }));
	    }

	    needed[index]--;
	    continue;
	}

	index = ohash->find_index(key);

	if (index) {
	    object type = ohash->m[index];

	    if (type->can_encode(value)) {
		Serialization.render_atom(str->encode(key), buf);
		Serialization.render_atom(type->encode(value), buf);
	    } else {
		throw(({ "Could not encode mapping value!\n", backtrace() }));
	    }
	    
	    continue;
	}

    }

    if (sizeof(needed)) {
	throw(({ "Mandatory variables missing.\n", backtrace() }));
    }

    return Serialization.Atom("_mapping", (string)buf);
}

int(0..1) can_decode(Serialization.Atom a) {
    if (!low_can_decode(a)) return 0;
    if (!a->parsed) low_decode(a);

    array(Serialization.Atom) list = a->pdata;
    int needed = sizeof(hash);

    if (sizeof(list)/2 < needed) return 0;

    for (int i = 0; i < sizeof(list); i += 2) {
	string key;

	if (str->can_decode(list[i])) {
	    key = str->decode(list[i]);
	    string index = hash->find_index(key);

	    if (index) {
		object type = hash->m[index];

		if (!type->can_decode(list[i+1])) {
		    return 0;
		}

		// TODO: not checking here if some index has been used twice may
		// do bad stuff... or not? TODO!!!
		needed--;
		continue;
	    }

	    index = ohash->find_index(key);

	    if (index) { // we dont complain about junk. could be an extension to the packet.
		object type = hash->m[index];

		if (!type->can_decode(list[i+1])) {
		    return 0;
		}
	    } 

	} else {
	    return 0;
	}
    }

    return !needed;
}

int(0..1) low_can_encode(mixed a) {
    return mappingp(a);
}

int(0..1) can_encode(mixed m) {
    if (!mappingp(m)) return 0;

    multiset needed = mkmultiset(indices(hash));

    if (sizeof(m) < sizeof(needed)) return 0;

    foreach (m; string key; mixed value) {

	string index = hash->find_index(key);

	if (!str->can_encode(key)) {
	    return 0;
	}

	if (index && needed[index]) {
	    object type = hash->m[index];

	    if (!type->can_encode(value)) {
		return 0;
	    }

	    needed[index]--;
	    continue;
	}

	index = ohash->find_index(key);

	if (index) {
	    object type = ohash->m[index];

	    if (!type->can_encode(value)) {
		return 0;
	    }
	    
	    continue;
	}

	// ignore junk. Warn maybe.
    }

    return !sizeof(needed);
}

string _sprintf(int c) {
    if (c == 'O') {
	return sprintf("Vars(%O, %O)", hash, ohash);
    }

    return 0;
}
