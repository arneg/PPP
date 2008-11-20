class Handler {
    // probably more to come, could also be inherited and extended
    function prefetch, postfetch;
    array(Serialization.Atom) sdata;
    string stage;
    object msig, vsig, dsig;
}

mapping(int:object) handler;

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
    m_delete(handler, id);
}
