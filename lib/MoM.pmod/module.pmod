class Mapping { // by embee, i'll ask for permission although i think this
		// probably is to straightforward to be protected under
		// copyright laws.
    mapping data;

    void create(mapping _data, mapping|void options)
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

    int `<(mixed arg)
    {
      return data < arg;
    }

    int `>(mixed arg)
    {
      return data > arg;
    }

    mixed `[](mixed index)
    {
      return data[index];
    }

    this_program `[]=(mixed index, mixed value)
    {
      data[index] = value;
      return this;
    }

    mixed `->(string index)
    { 
      return `[](index); 
    }

    this_program `->=(string index, mixed value)
    { 
      return `[]=(index, value); 
    }

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
}

class MoM {
    inherit Mapping;

    mapping(MoM:int) parents;
    mapping(mixed:MoM) emptychilds;
    mapping(MoM:multiset(mixed)) child2name;
    mixed name;

    void create(mixed|void name_) {
	name = name_;
	emptychilds = set_weak_flag(([ ]), Pike.WEAK_VALUES);
	child2name = set_weak_flag(([ ]), Pike.WEAK_INDICES);
	parents = set_weak_flag(([ ]), Pike.WEAK_INDICES);

	::create(([ ]));
    }

    mixed `[](mixed index) {
	mixed res;

	if (!index) index = 0; // prevents a zero_type > 0

	if (zero_type(res = ::`[](index))) {
	    if (!(res = emptychilds[index])) {
		res = emptychilds[index] = MoM(index);
		__add_child_name(res, index);
		res("_add_parent")(this);
	    }
	}

	return res;
    }

    mixed `[]=(mixed index, mixed value) {
	mixed t;

	if ((t = m_delete(emptychilds, index))
	    || ((t = ::`[](index))
		&& objectp(t)
		&& Program.inherits(object_program(t), MoM))) {
	    __remove_child_name(t, index);

	    if (!child2name[index]) {
		t("_remove_parent")(this);
	    }
	}

	if (objectp(value) && Program.inherits(object_program(value), MoM)) {
	    if (!sizeof(value)) {
		t = emptychilds[index] = value;
		__add_child_name(value, index);
	    } else {
		int gf = !sizeof(this);

		t = ::`[]=(index, value);

		if (gf) {
		    foreach (parents; MoM parent;) {
			parent("_got_filled")(this);
		    }
		}
	    }

	    value("_add_parent")(this);
	} else {
	    int gf = !sizeof(this);
	    
	    t = ::`[]=(index, value);

	    if (gf) {
		foreach (parents; MoM parent;) {
		    parent("_got_filled")(this);
		}
	    }
	}

	return t;
    }

    mixed `()(string index) { // believe me, i hate using this operator for
			      // that purpose more than you, but there's no
			      // other way other than pike-level function
			      // tables ("mappings") or deleting `->, `->=
			      // from MoM.Mapping, and that would be an
			      // atavistic endeavour.
	switch (index) {
	    case "_got_filled":
		return _got_filled;
	    case "_got_emptied":
		return _got_emptied;
	    case "_add_parent":
		return _add_parent;
	    case "_remove_parent":
		return _remove_parent;
	}

	return UNDEFINED;
    }

    void _got_filled(MoM child) {
	foreach (child2name[child]; mixed name;) {
	    m_delete(emptychilds, name);
	    this[name] = child;
	}
    }

    void _got_emptied(MoM child) {
	foreach (child2name[child]; mixed name;) {
	    emptychilds[name] = child;
	    _m_delete_(name);
	}
    }

    void _add_parent(MoM parent) {
	parents[parent]++;
    }

    void _remove_parent(MoM parent) {
	if (!--parents[parent]) {
	    m_delete(parents, parent);
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
	mixed res = ::_m_delete(index);

	if (!sizeof(this)) {
	    foreach (parents; MoM parent;) {
		parent("_got_emptied")(this);
	    }
	}

	return res;
    }

    mixed _m_delete(mixed index) {
	mixed res = _m_delete_(index);

	if (objectp(res) && Program.inherits(object_program(res), MoM)) {
	    res("_remove_parent")(this);
	}

	return res;
    }
}
