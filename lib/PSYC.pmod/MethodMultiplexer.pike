class Handler {
    // probably more to come, could also be inherited and extended
    function prefetch, postfetch;
    array(Serialization.Atom) sdata;
    string stage;
    object msig, vsig, dsig;
    int dead, async, ordered;
}

class StageIterator {
    inherit Iterator;

    array(string) mlist;
    string id;
    int index2, index3 = -1;
    object stage;

    Iterator _get_iterator() { return this; }

    void create(object stage, string method) {
	mlist = (method/"_");
	index2 = sizeof(mlist)-1;
	this_program::stage = stage;
	find_next();
    }

    void find_next() {
	for (;;) { 
	    if (index2 >=0 ) {
		if (--index3 >= 0) {
		    object h = stage->handler[id][index3];

		    if (h && !h->dead) { // race here
			return;	
		    } else {
			continue;
		    }
		} else {
		    id = mlist[0..index2]*"_";

		    index2--;
		    if (has_index(stage->handler, id)) {
			index3 = sizeof(stage->handler);
			continue;
		    }
		}
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
	find_next();

	return !!id;
    } 

    mixed value() {
	if (id && index3 > -1) return stage->handlers[id][index3];
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
    mapping(string:array(object)) handler = ([]);

    void create() {
    }

    .StageIterator get_iterator(string method) {
	return .StageIterator(this, method);
    }

    void add_handler(object h, string base) {
	if (!handler[base]) {
	    handler[base] = ({ });
	    set_weak_flag(handler[base], Pike.WEAK_VALUES);
	}

	handler[base] += ({ h });
    }
}

mapping(int:object) handler = ([]);
mapping(string:object) stages = ([]);
string start_stage = "start";

int get_new_id() {
    int i;
    while (has_index(handler, i = random(Int.NATIVE_MAX)));

    return i;
}

void set_start_stage(string start_stage) {
    this_program::start_stage = start_stage;
}

void add_stage(string name, object stage) {
    if (stages[name]) error("Sir, I am very sorry, but that seat is already taken.\n");
    stages[name] = stage;
}

int add_method(mapping specs, object child) {
    .Handler h = .Handler();

    h->stage = specs["stage"];
    h->msig = specs["method"];
    h->vsig = specs["vars"];
    h->dsig = specs["data"];
    if (specs["ordered"]) h->ordered = 1;
    if (specs["async"]) h->async = 1;
    if (specs["dead"]) h->dead = 1;

    if (!stages[h->stage]) error("I am in no such state! Shut your bloody piehole!");
    stages[h->stage]->add_handler(h, base);

    string base = h->msig->base;

    mixed f = `->(child, "prefetch_"+h->stage+"_"+base);
    if (callablep(f)) {
	h->prefetch = f;	
    }

    if (callablep(f = `->(child, h->stage+"_"+base))) {
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
