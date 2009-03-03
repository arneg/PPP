// raw items
string type;
string action;
string _data;

mixed _pdata;

// this may be the signature of the creator, needed for late rendering
object signature;

// this would be signature->data
TypedCache typed_cache = TypedCache();

class TypedCache {
    .Atom atom;
    multiset(object) signatures  = (<>);
    mapping(object:mixed) cache = ([]);

    mixed `[](mixed key) {
	if (!has_index(cache, key)) {
	    if (!has_index(signatures, key)) {
		signatures[key] = 1;
	    }

	    cache[key] = key->decode(atom);
	}

	return cache[key];
    }

    mixed `[]=(mixed key, mixed value) {
	cache = ([ key : value ]);
	atom->_data = 0;
	atom->_pdata = 0;
	atom->signature = key;
	return value;
    }

}

void create(string type, string data) {

    int i;

    if (-1 != (i = search(type, ';'))) {
	this_program::type = type[0..i-1];
	action = type[i+1..];
    } else {
	this_program::type = type;
    }

    this_program::data = data;
    typed_cache->atom = this;

    // if a signature dissapears, drop the corresponding data
    set_weak_flag(typed_data, Pike.WEAK_INDICES);
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

string|String.Buffer render(void|String.Buffer buf) {
    string ttype;

    if (action) {
	ttype = type + ";" + action;
    } else {
	ttype = type;
    }

    if (buf) {
	buf->add(sprintf("%s %d ", ttype, sizeof(data)));
	buf->add(data);
	return buf;
    } else return sprintf("%s %d %s", ttype, sizeof(data), data);
}

string _sprintf(int t) {
    if (t == 'O') {
	return sprintf("Atom(%s, %O)", type, action);
    }
}

int(0..1) `==(mixed a) {
    if (!objectp(a) || !Program.inherits(object_program(a), this_program)) {
	return 0;
    }

    return a->type == type && a->data == data && action == a->action;
}

array `pdata() {
    if (!_pdata) {
	if (!signature) error("cannot render unfinished atom without signature.\n");
	_data = signature->render(typed_data[signature]);
    }

    return _pdata;
}

array `pdata=(array a) {
    _pdata = a;
    typed_cache->cache = ([]);

    return a;
}

string `data() {
    if (!_data) {
	String.Buffer t = String.Buffer();

	foreach (`pdata();;Serialization.Atom a) {
	    a->render(t);
	}

	_data = t->get();
    }

    return _data;
}

string `data=(string s) {
    _data = s;
    pdata = 0;
    typed_cache->cache = ([]);

    return s;
}
