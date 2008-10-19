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

Serialization.Atom add(mapping v, void|function ret) {
    Serialization.Atom a = encode(v);
    a->action = "_add";

    if (ret) {
	return ret(a);
    } else {
	return a;
    }
}

Serialization.Atom sub(mapping v, void|function ret) {
    Serialization.Atom a = encode(v);
    a->action = "_sub";

    if (ret) {
	return ret(a);
    } else {
	return a;
    }
}

object index(string key, void|function ret) {
    write("index(%O)\n", key);
    if (!str->can_encode(key)) {
	error("bad index\n");
    }

    object vtype = hash[key] || ohash[key];

    if (vtype) {
	Serialization.Atom a = Serialization.Atom("_mapping", 0);
	a->action = "_index";
	Serialization.Atom f(Serialization.Atom v) {
	    write("return(%O)\n", key);
	    a->pdata = ({ str->encode(key), v });
	    if (ret) {
		return ret(a);
	    } else {
		return a;
	    }
	};

	return Serialization.CurryObject(vtype, f);
    } else {
	error("unknown index.\n");
    }

}

mapping apply(Serialization.Atom a, mapping state) {
    if (!a->action) {
	error("cannot apply data atom to a state.\n");
    }

    mapping t;
    int create;

    switch (a->action) {
    case "_add":
	t = decode(a);
	if (!state) return t;
	return state + t;
    case "_sub":
	t = decode(a);
	if (!state) return 0; // silently ignore non-existing
	return state - t;
    case "_index_create":
	create = 1;
    case "_index":
	if (!a->pdata && !low_decode(a)) error("odd number of atoms dont make a mapping. %O\n", a->pdata);
	for (int i = 0; i < sizeof(a->pdata); i+=2) {
	    string key = str->decode(a->pdata[i]);
	    
	    if (!has_index(state, key) && !create) {
		error("indexing non-existing entry.\n");
	    }

	    object vtype = hash[key] || ohash[key];
	    
	    // TODO: maybe issue a warning on else
	    if (vtype) state[key] = vtype->apply(a->pdata[i+1], state[key]);
	}
	return state;
    default:
	error("unsupported action.\n");
    }
}


int(0..1) low_decode(Serialization.Atom a) {
    if (!a->data) a->low_render();

    object parser = Serialization.AtomParser();

    parser->feed(a->data);
    array(Serialization.Atom) list = parser->parse_all();

    if (sizeof(list) & 1) return 0;

    // we keep the array.. more convenient
    a->pdata = list;

    return 1;
}

mapping decode(Serialization.Atom a) {

    if (a->typed_data[this]) return a->typed_data[this];

    if (!low_can_decode(a)) error("cannot decode %O\n", a);

    if (!a->pdata && !low_decode(a)) error("odd number of elements dont make a mapping.\n");

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
		continue;
	    } 

	    m[key] = list[i+1];
	} else {
	    throw(({ "Could not decode key!\n", backtrace() }));
	}
    }

    if (needed) {
	throw(({ "Mandatory variables missing.\n", backtrace()  }));
    }

    a->typed_data[this] = m;

    return m;
}

string render(mapping m) {
    String.Buffer buf = String.Buffer();
    
    foreach (m; string key; mixed value) {

	object type = hash[key] || ohash[key];

	if (!type) error("something totally unexpected happened during render. seems like %O has been changed since encode()\n", m);

	str->encode(key)->render(buf);
	type->encode(value)->render(buf);
    }

    return (string)buf;
}

Serialization.Atom encode(Serialization.Atom|mapping m) {
    if (low_can_decode(m)) return m;
    if (!can_encode(m)) error("cannot encode %O\n");

    Serialization.Atom atom = Serialization.Atom("_mapping", 0);
    atom->typed_data[this] = m;
    atom->signature = this;

    return atom;
}

int(0..1) can_decode(Serialization.Atom a) {
    if (!low_can_decode(a)) return 0;
    if (!a->pdata && !low_decode(a)) return 0;

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
    if (low_can_decode(m)) return 1;
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
