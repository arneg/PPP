inherit MMP.Utils.Debug;

object Method(string|void);
object Mapping(object, object);
object Any();
object get_instate(MMP.Packet);

class Handler {
    // probably more to come, could also be inherited and extended
    function prefetch, postfetch;
    string|mapping(string:Serialization.Atom|int) fetch;
    object stage;
    object msig, vsig, dsig;
    int active, dead, async;
    array(function) ordered;
    object oqueue;

    void activate() {
	dead = 0;
    }
}


// these are convenience objects to remove all handlers from one
// plugin at a time.
class Plugin {
    object plugin;
    mapping(int:object) handler = set_weak_flag(([]), Pike.WEAK_VALUES);
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

    this_program `+=(int steps) {
	if (steps < 0) error("Cannot move backwards.\n");

	while (steps-- > 0 && id) {
	    find_next(); 
	}

	return this;
    }

    this_program `+(int steps) {
	if (steps < 0) error("Cannot move backwards.\n");

	this_program new = this_program(stage, mlist*"_");
	new->index = index;
	new->id = id;

	new += steps;

	return new;
    }
}

class Stage {
    mapping(string:array(object)) handler = ([]);

    .MethodMultiplexer.StageIterator get_iterator(string method) {
	return .MethodMultiplexer.StageIterator(this, method);
    }

    void add_handler(object h, string base) {
	if (!handler[base]) {
	    handler[base] = set_weak_flag(({}), Pike.WEAK_VALUES);
	}

	handler[base] += ({ h });
    }
}

mapping(int:object) handler = ([]);
mapping(object:object) plugins = ([]);
mapping(string:object) stages = ([]);

string start_stage = "start";

int get_new_id(mapping m) {
    int i;
    while (has_index(m, i = random(Int.NATIVE_MAX)));

    return i;
}

void set_start_stage(string start_stage) {
    this_program::start_stage = start_stage;
}

void add_stage(string name, object stage) {
    if (stages[name]) error("Sir, I am very sorry, but that seat is already taken.\n");
    stages[name] = stage;
}

void add_plugin(object o) {
    .MethodMultiplexer.Plugin p = .MethodMultiplexer.Plugin();

    // this is circular. will clean up by hand, promise.
    p->plugin = o;
    plugins[o] = p;

    int ret = o->init_handler();

    if (ret) o->set_inited();
}

void remove_plugin(object o) {
    if (!has_index(plugins, o)) {
	error("dont know nothing about this plugin.");
    }

    .MethodMultiplexer.Plugin p = plugins[o];

    foreach (p->handler;int id;object handler) {
	remove_method(id);
    }

    p->plugin = 0;
    m_delete(plugins, o);
}

int add_method(mapping specs, object child) {
    .MethodMultiplexer.Handler h = .MethodMultiplexer.Handler();

    h->stage = stages[specs["stage"]];
    if (!h->stage) error("non supported stage %O.\n", specs["stage"]);
    h->msig = specs["method"];
    h->vsig = specs["vars"];
    h->dsig = specs["data"];
    if (1 == specs["ordered"]) {
	h->ordered = ({ h->stage->smaller,
		        h->stage->is_ok });
    } else if (arrayp(specs["ordered"])) {
	h->ordered = ({ specs["ordered"][0] || h->stage->smaller,
		        specs["ordered"][1] || h->stage->is_ok });
    } else {
	h->ordered = ({ h->stage->smaller,
		        h->stage->is_ok_weak });
    }

    if (specs["async"]) h->async = 1;
    if (specs["dead"]) h->dead = 1;

    // this type of activation prevents packets that come in prior
    // to initialization from being handled. 
    if (child->is_inited()) {
	h->active = 1;
    } else {
	child->init_cb_add(`->=, child, "active", 1); 
    }

    string base = h->msig->base;
    h->stage->add_handler(h, base);


    mixed f = `->(child, "prefetch_"+specs["stage"]+"_"+base);
    if (callablep(f)) {
	h->prefetch = f;	
    }

    if (callablep(f = `->(child, specs["stage"]+"_"+base))) {
	h->postfetch = f;	
    }

    if (!h->prefetch && !h->postfetch) {
	error("no callback found.");
    }

    f = specs["fetch"];

    if (!f) {
	f = ({});
    } else if (!arrayp(f)) {
	f = ({ f });
    }

    h->sdata = f;

    int id = add_handler(h);

    if (has_index(plugins, child)) {
	plugins[child]->handler[id] = h;
    }

    return id;
}

int add_handler(object h) {
    int id = get_new_id(handler);

    handler[id] = h;
    return id;
}

void remove_method(int id) {
    remove_handler(id);
}

void remove_handler(int id) {
    m_delete(handler, id)->dead = 1;
}

//! Entry point for processing PSYC messages through this handler framework.
//! @param p
//! 	An @[MMP.Packet] containing parseable PSYC as a string or @[PSYC.Packet].
//!
//! 	This will do everything from throwing to nothing if you provide something else.
void msg(MMP.Packet p) {
    debug("packet_flow", 3, "%O: msg(%O)\n", this, p);
    
    if (p["content_type"] == "psyc") {
	int f;
	switch (sprintf("%t", p->data)) {
	case "string":
	    array(Serialization.Atom) a = Serialization.parse_atoms(p->data);

	    if (sizeof(a) != 1) do_throw("uuuahahah");
	    p->data = a[0];
	    f = 1;
	case "object":
	    if (f || Program.inherits(object_program(p->data), Serialization.Atom)) {
		array(Serialization.Atom) t = Serialization.parse_atoms(p->data->data);
		PSYC.Packet packet = PSYC.Packet();

		int i;

		for (i = 0;i < sizeof(t); i++) {
		    Serialization.Atom atom = t[i];
		    if (Serialization.is_subtype_of("_mapping", atom->type) && !atom->action) {
			if (i > 0) {
			    packet->state_changes = t[0..i-1];
			}
			packet->vars = Mapping(Method(), Any())->decode(t[i]);

			i++;
			break;
		    } 
		}

		if (Serialization->is_subtype_of("_method", t[i]->type)) {
		    packet->mc = Method()->decode(t[i]);
		    if (sizeof(t) == ++i) {
			packet->data = t[i];
		    } else if (sizeof(t) > i){
			error("more than one data. looks broken.\n");
		    }
		} else {
		    error("broken psyc packet.\n");
		}

		p->data = packet;
		stages[start_stage]->handle_message(PSYC.Request(p, get_instate(p)->get_snapshot()), p->data->mc);
		break;
	    } else if (Program.inherits(object_program(p->data), Serialization.Atom)) {
		stages[start_stage]->handle_message(PSYC.Request(p, get_instate(p)->get_snapshot()), p->data->mc);
		break;
	    } else {
		do_throw("p->data is an object, but neither of class PSYC.Packet nor Serialization.Atom\n");
	    }
	    break;
	    default:
	    debug("packet_flow", 1, "Got Packet without data. maybe state changes?\n");
	    break;
	}
	
    }
}

