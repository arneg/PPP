object stage;
mapping _fun;


void create(object stage, mapping(int:function) retfun) {
    this_program::stage = stage;
    _fun = retfun;
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
	// prefetch
	//
	if (handler->prefetch) {
	    m = .Message(([
			    "mmp" : p,
			    "vsig" : handler->vsig,
			    "dsig" : handler->dsig,
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

