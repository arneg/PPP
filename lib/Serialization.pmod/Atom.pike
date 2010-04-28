// raw data
#ifdef TRACE_SOFT_MEMLEAKS
inherit MMP.Utils.Screamer;
#endif
string type, action, data;
string done;

#ifdef ENABLE_THREADS
Thread.Mutex mutex = Thread.Mutex();

object lock() {
	return mutex->lock();
}
#endif

// intermediate stuff (apply works on this)
// the type of this is psyc type specific
// needs a signature for downgrading to raw

// keep the most recent for late encoding
object signature;

// this would be signature->data
// readily parsed data
mapping(object:mixed) typed_data = ([]);

void create(string type, string data, void|string action) {
    this_program::type = type;
    this_program::data = data;
    if (action) this_program::action = action;
}

this_program clone() {
    if (!data) data = signature->render(this);
    this_program atom = this_program(type, data, action);
    atom->signature = signature;

    return atom;
}

void clear() {
	typed_data = ([]);
	data = 0;
	type = 0;
	signature = 0;
}

void condense() {
	if (signature) {
		if (!data) data = signature->render_payload(this);
		typed_data = ([]);
		signature = 0;
	}
}

#if 1
void set_raw(string type, string action, string data) {

    if (type != this_program::type) {
		clear();
    }

    this_program::action = action;
    this_program::data = action;
}
#endif

void set_typed_data(object signature, mixed d) {
    this_program::signature = signature;
    typed_data[signature] = d;
}

mixed get_typed_data(object signature) {
    return typed_data[signature];
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

string|Serialization.StringBuilder render(void|Serialization.StringBuilder buf) {

	if (done) {
		if (buf) {
			buf->add(done);
			return buf;
		} else return done;
	}

    if (buf) {
		if (!data) {
			data = signature->render_payload(this);
		}

		buf->add(done = sprintf("%s %d %s", type, sizeof(data), data));
		return buf;
    } else {
		if (!data) data = signature->render_payload(this);
		return (done = sprintf("%s %d %s", type, sizeof(data), data));
    }
}

string _sprintf(int t) {
    if (t == 'O') {
		return sprintf("Atom(%O, %O)", type, data || (signature && has_index(typed_data, signature) ? typed_data[signature] : UNDEFINED));
    } else if (t == 's') {
		return sprintf("Atom(%O)", type);
    }
}

/*
int __hash() {
    return hash(render());
}
*/
