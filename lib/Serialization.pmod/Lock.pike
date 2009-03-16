int(0..1) _locked = 0;

// to be called on unlock
object callbacks = MMP.Utils.Queue(); 

// n­ary tree
//this 'cyclic' dependency produces an error with pike7.8
//.Lock parent;
object parent;
mapping(object:object) children = ([]);

void lock(void|object child) {
    if (child) {
	if (has_index(children, child)) error("Already locked by child.\n");
	children[child] = child;
    } else if (_locked) {
	error("Already locked.\n");
    } else {
	_locked = 1;
    }
}

int(0..1) locked(void|object child) {
    return _locked || (child ? has_index(children, child) : sizeof(children));
}

void on_unlock(function callback, mixed ... args) {
    if (!locked()) error("Not locked.\n");
    callbacks->push(({ callback, args }));
}

void unlock(void|object child) {
    if (child) {
	if (_locked) error("Trying to be unlocked while stilled locked by child.\n");

	if (!has_index(children, child)) error("Not been locked by child. Something is broken. %O\n", children);

	m_delete(children, child);

#if 0
	if (parent && !sizeof(children)) {
	    parent->unlock(this); 
	    parent = 0;
	}
#endif
	unroll();
    } else if (_locked) {
	if (sizeof(children)) error("Still locked by children.\n");
	unroll();
	_locked = 0;
#if 0
	if (parent) {
	    parent->unlock(child);
	    parent = 0;
	}
#endif
    } else {
	error("Not locked%s.\n", (_locked ? "" : " by child"));
    }

    werror("UNLOCKED %O\n", this);
}

void unroll() {
    while (sizeof(callbacks)) {
	[function callback, array(mixed) args] = callbacks->shift();
//	MMP.Utils.invoke_later(callback, @args);
    }
}
