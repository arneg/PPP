object stage;
mapping _fun;

array(int) last_out = ({ 0, 0 });

object oqueue;

int smaller(array a, array b) {
    return a[1]["_id"] < b[1]["_id"];
}

int is_ok(array a) {
    return a[1]["_id"] == last_out[1]+1;
}

void create(object stage, mapping(int:function) retfun) {
    this_program::stage = stage;
    _fun = retfun;
    oqueue = PSYC.OrderedQueue(smaller, is_ok);
}

void handle_message(MMP.Packet p, string mc, mapping misc) {
    handle_step(stage->get_iterator(mc), p, mc, misc);
}

void handle_step(object iterator, MMP.Packet p, string mc, mapping misc) {
    prefetch(iterator, p, mc, misc);
}

void prefetch(object iterator, MMP.Packet p, string mc, mapping misc) {
    int seen;
    void fun(int|Serialization.Atom a) {
	if (objectp(a)) {
	    MMP.invoke_later(fetch, a, iterator, p, mc, misc);
	    return;
	}

	if (ret != PSYC.Handler.GOON) {
	    MMP.invoke_later(_fun[ret], p, misc);
	} else {
	    MMP.invoke_later(fetch, 0, iterator, p, mc, misc);
	}
    };

    foreach (iterator;; object handler) {
	.Message m;
	seen = 1;

	if (handler->ordered) {
	    oqueue->add(({ iterator, p, mc, misc }));

	    try_unroll();
	    return;
	}
	// prefetch
	//
	if (handler->prefetch) {
	    m = .Message(([
			    "mmp" : p,
			    "vsig" : handler->vsig,
			    "dsig" : handler->dsig,
			    "packet" : p->data,
			    "snapshot" : snapshot,
			 ]));
	    if (handler->async) {
		MMP.invoke_later(handler->prefetch, p, misc, fun);
	    } else {
		MMP.invoke_later(fun, handler->prefetch(p, misc));
	    }

	    return;
	}

	MMP.invoke_later(fetch, handler->ssig, iterator, p, mc, misc);
	return;
    }

    if (!seen) werror("no handler found.");
}

void fetch(Serialization.Atom sig, object iterator, MMP.Packet p, mapping misc) {
    storage->apply(sig, postfetch, iterator, p, mc, misc);
}

void postfetch(mapping data, object iterator, MMP.Packet p, mapping misc) {
    object handler = iterator->value();

    // do async
    
    void fun(int ret) {
	if (!has_index(_fun, ret)) {
	    error("invalid return value: %O\n", ret);
	}

	if (ret != PSYC.Handler.GOON) {
	    MMP.invoke_later(_fun[ret], p, misc);
	} else {
	    MMP.invoke_later(handle_message, iterator, p, misc);
	}
    };

    if (handler->async) {
	handler->postfetch(data, p, misc, fun);
    } else {
	fun(handler->postfetch(data, p, misc);
    }

    return;
}

void try_unroll() {
    array a = oqueue->get();

    if (a) {
	MMP.invoke_later(prefetch, @a);
    }
}

void leave(mapping data, object iterator, MMP.Packet p, mapping misc) {
    //last_out = max(last_out[*], ({ p["_state_id"], p["_id"] })[*]);
    last_out[0] = max(last_out[0], p["_state_id"]);
    last_out[1] = max(last_out[1], p["_id"]);
    try_unroll();
}
