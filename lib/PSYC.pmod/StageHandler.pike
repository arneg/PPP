object stage;
mapping _fun;


void create(object stage, mapping(int:function) retfun) {
    this_program::stage = stage;
    _fun = retfun;
}

void handle_message(MMP.Packet p, mapping misc) {
    string mc = p->data->mc;

    prefetch(stage->get_iterator(mc), p, misc);
}

void prefetch(object iterator, MMP.Packet p, mapping misc) {
    int seen;
    void fun(int|Serialization.Atom a) {
	if (objectp(a)) {
	    MMP.invoke_later(fetch, a, iterator, p, misc);
	    return;
	}

	switch (a) {
	case PSYC.Handler.STOP:
	    return;
	case PSYC.Handler.GOON:
	    MMP.invoke_later(fetch, 0, iterator, p, misc);
	    return;
	}
    };

    foreach (iterator;; object handler) {
	seen = 1;
	// prefetch
	//
	if (handler->prefetch) {
	    if (handler->async) {
		MMP.invoke_later(handler->prefetch, p, misc, fun);
	    } else {
		MMP.invoke_later(fun, handler->prefetch(p, misc));
	    }

	    return;
	}

	MMP.invoke_later(fetch, handler->ssig, iterator, p, misc);
	return;
    }

    if (!seen) werror("no handler found.");
}

void fetch(Serialization.Atom sig, object iterator, MMP.Packet p, mapping misc) {
    storage->apply(sig, postfetch, iterator, p, misc);
}

void postfetch(mapping data, object iterator, MMP.Packet p, mapping misc) {
    object handler = iterator->value();

    // do async
    
    void fun(int ret) {
	if (!has_index(_fun, ret)) {
	    error("invalid return value: %O\n", ret);
	}

	MMP.invoke_later(_fun[ret], iterator, p, misc);
    };

    if (handler->async) {
	handler->postfetch(data, p, misc, fun);
    } else {
	fun(handler->postfetch(data, p, misc);
    }

    return;
}

