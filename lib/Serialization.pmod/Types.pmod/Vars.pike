inherit .Mapping;

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

object get_ktype(mixed key) { return str; }
object get_vtype(mixed key, object ktype, mixed value) {
    if (stringp(key)) {
	return hash[key] || ohash[key];
    }
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
		    error("evil, cannot decode value!\n");
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
		    error("evil, cannot decode value!\n");
		}

		m[index] = value;
		continue;
	    } 

	    m[key] = list[i+1];
	} else {
	    error("Could not decode key!\n");
	}
    }

    if (needed) {
	error("Mandatory variables missing.\n");
    }

    a->typed_data[this] = m;

    return m;
}

int(0..1) can_decode(Serialization.Atom a) {
    if (mixed err = catch { decode(a); }) {
	return 0;
    }

    return 1;
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
