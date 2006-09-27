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

class MoM { // hail saga. great fun in 61 lines!
    inherit Mapping;

    function p_emptied, p_filled;
    mapping(mixed:MoM) emptychilds;
    mixed name;

    void create(mixed|void name_, function|void p_emptied_,
		function|void p_filled_) {
	emptychilds = set_weak_flag(([ ]), Pike.WEAK_VALUES);
	name = name_;
	p_emptied = p_emptied_;
	p_filled = p_filled_;

	::create(([ ]));
    }

    mixed `[](mixed index) {
	mixed res;

	if (!index) index = 0; // prevents a zero_type > 0

	if (zero_type(res = ::`[](index))) {
	    res = emptychilds[index]
		    || (emptychilds[index] = MoM(index, _got_emptied,
						 _got_filled));
	}

	return res;
    }

    mixed `[]=(mixed index, mixed value) {
	if (!sizeof(this) && p_filled && !zero_type(name)) {
	    // TODO:: zero_type should never be true, why do i check it?
	    p_filled(this, name);
	}

	return ::`[]=(index, value);
    }

    void _got_filled(MoM child, mixed name) {
	m_delete(emptychilds, name);
	this[name] = child;
    }

    void _got_emptied(MoM child, mixed name) {
	emptychilds[name] = child;
	m_delete(this, name);
    }

    mixed _m_delete(mixed index) {
	mixed res = ::_m_delete(index);

	if (!sizeof(this) && p_emptied && !zero_type(name)) {
	    // TODO:: zero_type should never be true, why do i check it?
	    p_emptied(this, name);
	}

	return res;
    }
}
