class Handler {
    // probably more to come, could also be inherited and extended
    function prefetch, postfetch;
    array(Serialization.Atom) sdata;
    string stage;
    object msig, vsig, dsig;
    int dead = 0;
}

class StageIterator {
    array(string) mlist;
    string id;
    int index;
    object stage;

    void create(object stage, string method) {
	mlist = (method/"_");
	index = sizeof(mlist)-1;
	this_program::stage = stage;
	find_next();
    }

    void find_next() {
	while (1) { 
	    if (index >= 0) {
		id = mlist[0..index]*"_";

		index--;
		if (has_index(state->handler, id)) return;
	    } else {
		id = UNDEFINED;
		return;
	    }
	}
    }

    mixed index() {
	return id;	
    }

    int(0..1) next() {
	id = find_next();

	return !!id;
    }

    mixed value() {
	if (id) return stage->handlers[id];
	else return UNDEFINED;
    }

    .this_program `+=(int steps) {
	if (steps < 0) error("Cannot move backwards.\n");

	while (steps-- > 0 && id) {
	    find_next(); 
	}

	return this;
    }

    .this_program `+(int steps) {
	if (steps < 0) error("Cannot move backwards.\n");

	.this_program new = .this_program(stage, mlist*"_");
	new->index = index;
	new->id = id;

	new += steps;

	return new;
    }
}

class Stage {
    mapping(string:object) handler = ([]);

    void create() {
	set_weak_flag(handler, Pike.WEAK_VALUES);
    }

    .StageIterator get_iterator(string method) {
	return .StageIterator(this, method);
    }
}

mapping(int:object) handler = ([]);
mapping(string:object) stages = ([]);

int get_new_id() {
    int i;
    while (has_index(handler, i = random(Int.NATIVE_MAX))) {} 

    return i;
}

int add_method(mapping specs) {
    .Handler h = .Handler();

    h->stage = specs["stage"];
    h->msig = specs["method"];
    h->vsig = specs["vars"];
    h->dsig = specs["data"];
    string base = h->msig->base;

    mixed f = `->(this, "prefetch_"+h->stage+"_"+base);
    if (callablep(f)) {
	h->prefetch = f;	
    }

    if (callablep(f = `->(this, h->stage+"_"+base))) {
	h->postfetch = f;	
    }

    if (!h->prefetch && !h->postfetch) {
	error("no callback found.");
    }

    f = specs["fetch"];

    if (!f) {
	f = ({});
    } else if (!array(f)) {
	f = ({ f });
    }

    h->sdata = f;

    return add_handler(h);
}

int add_handler(object h) {
    int id = get_new_id();

    handler[id] = h;
    return id;
}

void remove_method(int id) {
    remove_handler(id);
}

void remove_handler(int id) {
    m_delete(handler, id)->dead = 1;
}
