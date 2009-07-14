// raw data
string type, action, data;

inherit .Lock;

// intermediate stuff (apply works on this)
// the type of this is psyc type specific
// needs a signature for downgrading to raw
int(0..1) _has_pdata = 0;

#if __MINOR__ >= 7 && __MAJOR__ >= 7
mixed _pdata;

mixed `pdata() {
    if (_has_pdata) return _pdata;
    return UNDEFINED;
}

mixed `pdata=(mixed value) {
    _pdata = value;
    _has_pdata = 1;
}

void delete_pdata() {
    _pdata = _has_pdata = 0;
}
#else 
mixed pdata;
mixed `->(string key) {
    if (key == "pdata") {
	if (_has_pdata) return pdata;
	return UNDEFINED;
    }

    return ::`->(key);
}

mixed `->=(string key, mixed value) {
    if (key == "pdata") {
	pdata = value;
	_has_pdata = 1;
    }

    return ::`->=(key, value);
}
void delete_pdata() {
    pdata = _has_pdata = 0;
}
#endif

int(0..1) has_pdata() {
    return _has_pdata;
}


// keep the most recent for late encoding
object signature;

// this would be signature->data
// readily parsed data
mapping(object:mixed) typed_data = set_weak_flag(([]), Pike.WEAK_INDICES);

object child;

array(object) path() {
    if (!signature) error("Atom doesnt know its signature. Dont use sig_list() with raw atoms.\n");

    if (child) {
	return ({ signature }) + child->path();
    } else {
	return ({ signature });
    }
}

void create(string type, string data, void|string action) {

    int i;

    this_program::type = type;
    this_program::data = data;
    if (action) this_program::action = action;
}

this_program clone() {
    make_raw();
    this_program atom = this_program(type, data, action);
    atom->signature = signature;

    return atom;
}

void set_raw(string type, string action, string data) {

    if (type != this_program::type) {
	// this is no use anymore
	signature = 0;
	this_program::type = type;
    }

    this_program::action = action;
    this_program::data = action;

    typed_data = set_weak_flag(([]), Pike.WEAK_INDICES);
    delete_pdata();
}

void set_pdata(mixed a) {
    if (!signature) {
	error("This will render the Atom unusable.\n");	
    }
    pdata = a;
    data = 0;
    typed_data = set_weak_flag(([]), Pike.WEAK_INDICES);
}

void set_typed_data(object signature, mixed d) {
    this_program::signature = signature;
    typed_data[signature] = d;
    delete_pdata();
    data = 0;
}

void make_raw() {
    if (data) {
		return;
    }

    if (!signature) {
		error("Cannot make %O raw without signature.\n", this);
    }

    signature->to_raw(this);
}

mixed get_pdata(void|object signature) {
    object sig;

    if (pdata) return pdata;

    if (signature) {
	sig = signature;
	if (!this_program::signature) this_program::signature = signature;
    } else {
	sig = this_program::signature;
    }

    if (!sig) error("Cannot produce pdata without signature.\n");

    if (has_index(typed_data, sig)) {
	sig->done_to_medium(this);
    } else {
	sig->raw_to_medium(this);
    }

    return pdata;
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

    if (!data) make_raw();

    if (action) {
		ttype = type + ":" + action;
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
		return sprintf("Atom(%s, %O)", type, data || (has_pdata() ? pdata : (signature && has_index(typed_data, signature) ? typed_data[signature] : UNDEFINED)));
    } else if (t == 's') {
		return sprintf("Atom(%s)", type);
    }
}

// there is some room for optimizations here.
int(0..1) `==(mixed a) {
    if (!objectp(a) || !Program.inherits(object_program(a), this_program)) {
	return 0;
    }

    make_raw();

    return a->type == type && action == a->action && a->data == data;
}

int __hash() {
    return hash(render());
}
