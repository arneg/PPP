class Mapping { // by embee, i'll ask for permission although i think this
		// probably is to straightforward to be protected under
		// copyright laws.
    mapping data;

    void create(mapping _data)
    {
      data = _data;

    }

    array _values()
    {
      return values(data);
    }

    mixed cast(string type)
    {
      switch(type)
      {
	case "int":
	  return (int)data;
	case "float":
	  return (float)data;
	case "string":
	  return (string)data;
	case "array":
	  return (array)data;
	case "multiset":
	  return (multiset)data;
	case "mapping":
	  return (mapping)data;
	default:
	  throw(({ sprintf("Cannot cast %O to %s.\n", this, type), backtrace() }));
      }
    }

    int _sizeof()
    {
      return sizeof(data);
    }

    array _indices()
    {
      return indices(data);
    }

    this_program `+(mixed arg, mixed ... rest)
    {
      return this_program(predef::`+(data, arg, @rest));
    }

    this_program ``+(mixed arg, mixed ... rest)
    {
      return this_program(predef::`+(arg, @rest, data));
    }
     
    this_program `-(mixed arg)
    {
      return this_program(data-arg);
    }

    this_program ``-(mixed arg)
    {
      return this_program(arg-data);
    }

    this_program `&(mixed ... args)
    {
      return this_program(predef::`&(data, @args));
    }

    this_program ``&(mixed ... args)
    {
      return this_program(predef::`&(@args, data));
    }

    this_program `|(mixed ... args)
    {
      return this_program(predef::`|(data, @args));
    }

    this_program ``|(mixed ... args)
    {
      return this_program(predef::`|(@args, data));
    }

    this_program `^(mixed ... args)
    {
      return this_program(predef::`^(data, @args));
    }

    this_program ``^(mixed ... args)
    {
      return this_program(predef::`^(@args, data));
    }

    int _equal(mixed arg)
    {
      return equal(data, arg);
    }

// kept making problems in combination with multisets.. don't know what to do.
// could use a mapping instead... (multiset explicit of MoM the troublemaker is)
#if 0
    int `<(mixed arg)
    {
      return data < arg;
    }

    int `>(mixed arg)
    {
      return data > arg;
    }
#endif

    mixed `[](mixed index)
    {
      return data[index];
    }

    this_program `[]=(mixed index, mixed value)
    {
      data[index] = value;
      return this;
    }

    // embee wisely added these operators for total mapping-like functioning,
    // but unfortunately we're planning so far advanced mappings that we
    // just need the operator to allow us access to the object's internals
    // (using `()() for that really sucks noodles.
#if 0
    mixed `->(string index)
    { 
      return `[](index); 
    }

    this_program `->=(string index, mixed value)
    { 
      return `[]=(index, value); 
    }
#endif

    int _is_type(string basic_type)
    {
      return basic_type == "mapping";
    }

    string _sprintf(int conversion_type, mapping(string:int)|void params)
    {
      return sprintf("%"+(string)({ conversion_type }), data);
    }

    mixed _m_delete(mixed index)
    {
      return m_delete(data, index);
    }

    Iterator _get_iterator()
    {
      return get_iterator(data);
    }

    mixed _search(mixed needle, mixed|void start)
    {
      return search(data, needle, start);
    }

    int _has_index(mixed index) { // not official part of the api yet
	return has_index(data, index);
    }
}

#ifdef MOMDEBUG
int foo;
#endif

class MoM {
    inherit Mapping;

#ifdef MOMDEBUG
    mixed id; // can be set via o->id = ...; for identifying in destroy-debug
#endif

    mapping(MoM:int) parents;
    multiset(MoM) explicit;
    mapping(mixed:MoM) emptychilds;
    mapping(MoM:multiset(mixed)) child2name;
    int in_destroy;

    void create(mapping|void data) {
	emptychilds = set_weak_flag(([ ]), Pike.WEAK_VALUES);
	child2name = set_weak_flag(([ ]), Pike.WEAK_INDICES);
	parents = set_weak_flag(([ ]), Pike.WEAK_INDICES);
	explicit = (< >); // none weak, because that's the only thing we need
			  // it for.
			  // (if somedone does a[x] = b[y], than b[y] better
			  // doesn't get garbage collected away if empty,
			  // otherwise they won't correlate.)

#ifdef MOMDEBUG
	id = ++foo;
#endif

	::create(data || ([ ]));
    }

    void destroy() {
	in_destroy = 1; // so we do not care of incoming _unset_explicit()s

	// unfortunately we can't find out here whether we were not exlicit.
	// in case of sizeof(explicit), of course we were. but we can't be sure
	// we were not explicit, as some parents might have been destroyed
	// first, so we tell anyone left, just in case.
	foreach (parents; MoM parent;) {
	    parent->_unset_explicit(this);
	}

	// additionally, tell any explicit child that we are not it's parent
	// any longer, as that might relieve them from their major burden of
	// explicitness.
	foreach (explicit; MoM e;) {
	    if (e) e->_totally_remove_parent(this);
	}

#ifdef MOMDEBUG
	werror("MoM(id: %O) destroyed.\n", id);
#endif
    }

    mixed `[](mixed index) {
	mixed res;

	if (!index) index = 0; // prevents a zero_type > 0

	if (zero_type(res = ::`[](index))) {
	    if (!(res = emptychilds[index])) {
		res = emptychilds[index] = this_program();
		__add_child_name([object(MoM)]res, index);
		([object(MoM)]res)->_add_parent(this);
	    }
	}

	return res;
    }

    mixed `[]=(mixed index, mixed value) {
	mixed t;

	if ((t = m_delete(emptychilds, index))
	    || (t = ::`[](index)) && MoMp(t)) {
	    if (t != value) {
		__remove_child_name([object(MoM)]t, index);
		([object(MoM)]t)->_remove_parent(this);
	    }
	}

	if (MoMp(value)) {
	    if (t != value) {
		__add_child_name([object(MoM)]value, index);
		([object(MoM)]value)->_add_parent(this);
	    }

	    if (!sizeof([object]value)) {
		t = emptychilds[index] = [object(MoM)]value;
	    } else {
		int gf = !sizeof(this);

		t = ::`[]=(index, value);

		if (gf) {
		    foreach (parents; MoM parent;) {
			parent->_got_filled(this);
		    }
		}
	    }
	} else {
	    int gf = !sizeof(this);
	    
	    t = ::`[]=(index, value);

	    if (gf) {
		foreach (parents; MoM parent;) {
		    parent->_got_filled(this);
		}
	    }
	}

	return t;
    }

    void _got_filled(MoM child) {
	foreach (child2name[child]; mixed name;) {
	    //m_delete(emptychilds, name);
	    this[name] = child;
	    //::`[]=(name, child);
	}
    }

    void _got_emptied(MoM child) {
	foreach (child2name[child]; mixed name;) {
	    emptychilds[name] = child;
	    _m_delete_(name);
	}
    }

    void __eventually_unset_explicit() {
	if (!sizeof(explicit)
		&& sizeof(parents) == 1
		&& parents[indices(parents)[0]] == 1) {
	    foreach (parents; MoM p;) {
		p->_unset_explicit(this);
	    }
	}
    }

    void _add_parent(MoM parent) {
#ifdef MOMDEBUG
	werror("MoM(id: %O) _add_parent: %O\n", id, backtrace());
#endif

	parents[parent]++;

	if (!sizeof(explicit)
		&& (sizeof(parents) > 1 
		    || sizeof(parents) == 2
		    && parents[indices(parents)[0]] > 1)) {
	    foreach (parents; MoM parent;) {
		parent->_set_explicit(this);
	    }
	}
    }

    void _remove_parent(MoM parent) {
	if (--parents[parent] <= 0) {
	    m_delete(parents, parent);
	}

	parent->_unset_explicit(this);
	__eventually_unset_explicit();
    }

    void _totally_remove_parent(MoM parent) {
	m_delete(parents, parent);
	__eventually_unset_explicit();
    }

    void _set_explicit(MoM child) {
#ifdef MOMDEBUG
	werror("MoM(id: %O): _set_explicit()\n", id);
#endif
	int s = sizeof(explicit);

	explicit[child] = 1;

	if (!s && sizeof(parents) == 1 && parents[indices(parents)[0]] == 1) {
	    foreach (parents; MoM parent;) {
		parent->_set_explicit(this);
	    }
	}
    }

    void _unset_explicit(MoM child) {
#ifdef MOMDEBUG
	werror("MoM(id: %O)_unset_explicit(), %O\n", id, backtrace());
#endif

	if (in_destroy) return;

	if (explicit[child]) {
	    explicit -= (< child >);

	    if (!sizeof(explicit)
		    && sizeof(parents) == 1
		    && parents[indices(parents)[0]] == 1) {
		foreach (parents; MoM parent;) {
		    parent->_unset_explicit(this);
		}
	    }
	}
    }

    void __add_child_name(MoM child, mixed name) {
	if (!child2name[child]) {
	    child2name[child] = set_weak_flag((< >), Pike.WEAK_VALUES);
	}

	child2name[child][name] = 1;
    }

    void __remove_child_name(MoM child, mixed name) {
	if (!child2name[child]) return;

	child2name[child][name] = 0;
	
	if (sizeof(child2name[child])) {
	    m_delete(child2name, child);
	}
    }

    mixed _m_delete_(mixed index) {
	mixed res;

	if (_has_index(index)) {
	    res = ::_m_delete(index);
	} else {
	    res = m_delete(emptychilds, index);
	}

	if (!sizeof(this)) {
	    foreach (parents; MoM parent;) {
		parent->_got_emptied(this);
	    }
	}

	return res;
    }

    mixed _m_delete(mixed index) {
	mixed res = _m_delete_(index);

	if (MoMp(res)) {
	    // strict typing sucks..
	    ([object(MoM)]res)->_remove_parent(this);
	    __remove_child_name([object(MoM)]res, index);
	}

	return res;
    }

    mixed get(mixed ... keys) {
	mixed res = this;

	if (!sizeof(keys)) {
	    throw(({ "no arguments supplied to get()\n", backtrace() }));
	}

	foreach (keys;; mixed key) {
	    res = res[key];
	}

	return res;
    }

    mixed set(mixed ... args) {
	mixed t = this;

	if (sizeof(args) <= 1) {
	    throw(({ "not enough arguments supplied to set()\n",
		     backtrace() }));
	}

	for (int i = 0; i < sizeof(args) - 2; i++) {
	    t = t[args[i]];
	}

	return t[args[-2]] = args[-1];
    }
}

int MoMp(mixed m) {
    mixed t;

    if (programp(t = object_program(m)) && Program.inherits([program]t, MoM)) {
	return 1;
    } else {
	return 0;
    }
}
