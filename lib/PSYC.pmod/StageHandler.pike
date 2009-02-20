inherit MMP.Utils.Debug;

object storage() {
    return stage->storage();
}

object stage;
mapping _fun;
mapping oqueues = ([ ]);

// this is not the last one that left the stage but rather the last one that
// was used to apply state
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

void create(mapping(int:function) retfun) {
    stage = .MethodMultiplexer.Stage();
    _fun = retfun;
}

void handle_message(.Request r, string mc) {
    handle_step(stage->get_iterator(mc), r, mc);
}

void handle_step(object iterator, .Request r, string mc) {
    prefetch(iterator, r, mc);
}

void prefetch(object iterator, .Request r, string mc) {
    int seen;
    void fun(int|Serialization.Atom a) {
	if (objectp(a)) {
	    MMP.Utils.invoke_later(fetch, a, iterator, r, mc);
	    return;
	}

	if (a != PSYC.Handler.GOON) {
	    if (!_fun[a]) {
		do_throw("Handler gave invalid return result %O.\n", a);
	    }

	    MMP.Utils.invoke_later(_fun[a], r);
	} else {
	    MMP.Utils.invoke_later(fetch, 0, iterator, r, mc);
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
	// prefetch
	//
	if (handler->prefetch) {
	    /*
	    m = .Message(([
			    "mmp" : p,
			    "vsig" : handler->vsig,
			    "dsig" : handler->dsig,
			    "packet" : p->data,
			    "snapshot" : snapshot,
			 ]));
	    */
	    if (handler->async) {
		MMP.Utils.invoke_later(handler->prefetch, r->p, r->misc, fun);
	    } else {
		MMP.Utils.invoke_later(fun, handler->prefetch(r->p, r->misc));
	    }

	    return;
	}

	MMP.Utils.invoke_later(fetch, handler->fetch, iterator, r);
	return;
    }

    if (!seen) werror("no handler found.");
}

void fetch(mapping(string:Serialization.Atom|int)|string fetch, object iterator, .Request r) {
    if (mappingp(fetch)) {
	void callback(int ok, mapping value) {
	    if (ok) {
		MMP.Utils.invoke_later(postfetch, value, iterator, r);
	    } else {
		werror("could not fetch data from storage.\n");
	    }
	};

	storage()->multi_apply(fetch, callback);
    } else { 
	void callback(int ok, mixed value) {
	    if (ok) {
		MMP.Utils.invoke_later(postfetch, ([ fetch : value ]), iterator, r);
	    } else {
		werror("could not fetch data from storage.\n");
	    }
	};
	
	storage()->get(fetch, callback);
    } 
}

void postfetch(mapping data, object iterator, .Request r) {
    object handler = iterator->value();

    // do async
    
    void fun(int ret) {
	if (!has_index(_fun, ret)) {
	    error("invalid return value: %O\n", ret);
	}

	if (ret != PSYC.Handler.GOON) {
	    MMP.Utils.invoke_later(_fun[ret], r);
	} else {
	    MMP.Utils.invoke_later(handle_message, iterator, r);
	}
    };

    if (handler->async) {
	handler->postfetch(data, r->p, r->misc, fun);
    } else {
	fun(handler->postfetch(data, r->p, r->misc));
    }

    return;
}

void try_unroll() {
    foreach (oqueues;object queue;int size) {
	while (array a = queue->get()) {
	    MMP.Utils.invoke_later(prefetch, @a);
	    if (!--oqueues[queue]) {
		m_delete(oqueues, queue);
		break; // optimization
	    }
	}
    }
}

void leave(mapping data, object iterator, .Request r) {
    //last_out = max(last_out[*], ({ p["_state_id"], p["_id"] })[*]);
    last_out[0] = max(last_out[0], r->p["_state_id"]);
    last_out[1] = max(last_out[1], r->p["_id"]);
    try_unroll();
}
