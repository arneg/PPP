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
    if (objectp(key)) {
	if (str->can_decode(key)) {
	    key = str->decode(key);
	}
    }

    if (stringp(key)) {
	return hash[key] || ohash[key];
    } 
}

// these two ignore unknown keys
void done_to_medium(Serialization.Atom atom) {
    mapping m = ([]), done = atom->typed_data[this];
    if (!mappingp(done)) error("Broken done state.\n");

    foreach (done; mixed key; mixed value) {
	object ktype = get_ktype(key);
	if (!ktype) continue;
	object vtype = get_vtype(key, ktype, value);
	if (!vtype) continue;
	Serialization.Atom mkey = ktype->encode(key);
	Serialization.Atom mval = vtype->encode(value);
	m[mkey] = mval;
    }

    atom->pdata = m;
}

void medium_to_done(Serialization.Atom atom) {
    mapping done = ([]), m = atom->pdata;
    if (!mappingp(m)) error("Broken medium state.\n");

    foreach (m;Serialization.Atom mkey;Serialization.Atom mval) {
	object ktype = get_ktype(mkey);
	if (!ktype) continue;
	object vtype = get_vtype(mkey, ktype, mval);
	if (!vtype) {
	    werror("No vtype for %O:%O\n", mkey, mval);
	    continue;
	}

	mixed key = ktype->decode(mkey);
	mixed val = vtype->decode(mval);
	done[key] = val;
    }

    atom->typed_data[this] = done;
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
		werror("%O cannot encode %O\n", type, value);
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
