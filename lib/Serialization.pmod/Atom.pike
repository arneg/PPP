// raw items
string type;
string action;
string data;

mixed pdata;

// this may be the signature of the creator, needed for late rendering
object signature;

// this would be signature->data
mapping(object:mixed) typed_data  = ([]);

void create(string type, string data) {

    int i;

    if (-1 != (i = search(type, ';'))) {
	this_program::type = type[0..i-1];
	action = type[i+1..];
    } else {
	this_program::type = type;
    }

    this_program::data = data;

    // if a signature dissapears, drop the corresponding data
    set_weak_flag(typed_data, Pike.WEAK_INDICES);
}

void set_pdata(array(Signature.Atom) a) {
    typed_data = ([]);
    data = 0;
    pdata = a;
}

void set_data(string data) {
    typed_data = ([]);
    this_program::data = data;
    pdata = 0;
}

void set_tdata(object signature, mapping m) {
    typed_data = ([ signature : m ]);
    this_program::signature = signature;
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

void low_render() {
    if (!signature) error("cannot render unfinished atom without signature.\n");
    data = signature->render(typed_data[signature]);
}

string `data() {
    if (
}

string|String.Buffer render(void|String.Buffer buf) {
    if (!data) {
	if (!pdata) {
	    low_render();
	} else {
	    String.Buffer t = String.Buffer();

	    foreach (pdata;;Serialization.Atom a) {
		a->render(t);
	    }

	    data = t->get();
	}
    }

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
