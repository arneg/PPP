object stage;
mapping _fun;
mapping oqueues = ([ ]);

array(int) last_out = ({ 0, 0 });

int smaller(array a, array b) {
    return a[1]["_id"] < b[1]["_id"];
}

int is_ok(array a) {
    return a[1]["_id"] == last_out[1]+1;
}

int is_ok_weak(array a) {
    return !(last_out[0] == a[0]-1 && last_out[1] != a[1]-1);
}
void create(object stage, mapping(int:function) retfun) {
    this_program::stage = stage;
    _fun = retfun;
}

void handle_message(object r, string mc) {
    handle_step(stage->get_iterator(mc), r, mc);
}

void handle_step(object iterator, object r, string mc) {
    prefetch(iterator, r, mc);
}

void prefetch(object iterator, object r, string mc) {
    int seen;
    void fun(int|Serialization.Atom a) {
	if (objectp(a)) {
	    MMP.invoke_later(fetch, a, iterator, r, mc);
	    return;
	}

	if (ret != PSYC.Handler.GOON) {
	    if (!_fun[ret]) {
		do_throw("Handler gave invalid return result %O.\n", ret);
	    }

	    MMP.invoke_later(_fun[ret], r);
	} else {
	    MMP.invoke_later(fetch, 0, iterator, r, mc);
	}
    };

    foreach (iterator;; object handler) {
	.Message m;
	seen = 1;

	if (handler->ordered) {
	    if (!handler->oqueue) handler->oqueue = PSYC.OrderedQueue(@handler->orderd);

	    handler->oqueue->add(({ iterator, r, mc }));
	    oqueues[handler->oqueue]++;

	    try_unroll();
	    return;
	}
	// apply state if possible
	foreach (r->state_changes;Serialization.Atom change;) {

	    if (vsig->can_decode(change)) {
		state->apply(vsig, change);
		// flagellate the applied one
		m_delete(r->state_changes, change);
	    }
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
    foreach (oqueues;; queue) {
	while (array a = oqueue->get()) {
	    MMP.invoke_later(prefetch, @a);
	    if (!--oqueues[queue]) {
		m_delete(oqueues, queue);
		break; // optimization
	    }
	}
    }
}

void leave(mapping data, object iterator, MMP.Packet p, mapping misc) {
    //last_out = max(last_out[*], ({ p["_state_id"], p["_id"] })[*]);
    last_out[0] = max(last_out[0], p["_state_id"]);
    last_out[1] = max(last_out[1], p["_id"]);
    try_unroll();
}
