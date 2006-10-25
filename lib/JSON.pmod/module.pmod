// vim:syntax=lpc
// $Id: module.pmod,v 1.7 2006/10/25 17:15:37 tobij Exp $

mixed parse(string json, program|void objectb, program|void arrayb) {
#if constant(Public)
# if constant(Public.Parser)
#  if constant(Public.Parser.JSON)
    if (!(objectb || arrayb)) {
	return Public.Parser.JSON.parse(json);
    }
#  endif
# endif
#endif

    return parse_pike(json, objectb, arrayb);
}

.JSONTokener tok = .JSONTokener(0);

mixed parse_pike(string json, program|void objectb, program|void arrayb) {
    tok->setup(json, objectb, arrayb);
    return tok->nextObject();
    //return .JSONTokener(json, objectb, arrayb)->nextObject();
}

mixed serialize(object|mapping|array|string|int|float thing) {
#if constant(Public)
# if constant(Public.Parser)
#  if constant(Public.Parser.JSON)
    return Public.Parser.JSON.serialize(thing);
#  endif
# endif
#endif

    return serialize_pike(thing);
}

mixed serialize_pike(object|mapping|array|string|int|float thing) {
    int type;

    if (stringp(thing)) {
	return _string2json(thing);
    } else if (intp(thing)) {
	return _int2json(thing);
    } else if (floatp(thing)) {
	return _float2json(thing);
    } else if (mappingp(thing)) {
	return _mapping2json(thing);
    } else if (arrayp(thing)) {
	return _array2json(thing);
    } else {
	throw(Error.Generic(sprintf("Could not serialize %O, it's a %O, but I "
				    "can't handle " "that.\n",
				    thing, _typeof(thing))));
    }
}

string _string2json(string|object s) {
    String.Buffer buf = String.Buffer(sizeof(s) + 10);
    function(string... : int) add = buf->add;

    add("\"");

    foreach (s;; int c) {
	switch (c) {
	    case '\\':
	    case '"':
		add("\\");
		add(String.int2char(c));
		break;
	    case '\b':
		add("\\b");
		break;
	    case '\f':
		add("\\f");
		break;
	    case '\n':
		add("\\n");
		break;
	    case '\r':
		add("\\r");
		break;
	    case '\t':
		add("\\t");
		break;
	    default:
		if (c < ' ') {
		    add(sprintf("\\u%04x", c));
		} else {
		    add(String.int2char(c));
		}

		break;
	}
    }

    add("\"");

    return buf->get_copy();
}

string _int2json(int|object thing) {
    if (zero_type(thing)) {
	return "null";
    } else {
	return (string)thing;
    }
}

string _float2json(float|object f) {
    string s = lower_case((string)f);

    if (!has_value(s, 'e') && has_value(s, '.')) {
	while (has_suffix(s, "0")) {
	    s = s[..sizeof(s) - 2];
	}

	if (has_suffix(s, ".")) {
	    s += "0";
	}
    }

    return s;
}

string _array2json(array|object a) {
    String.Buffer buf = String.Buffer();
    function(string... : int) add = buf->add;

    add("[");

    foreach (a; int pos; mixed v) {
	if (pos) add(",");

	add(serialize_pike(v));
    }

    add("]");

    return buf->get();
}

string _mapping2json(mapping|object m) {
    String.Buffer buf = String.Buffer();
    function(string... : int) add = buf->add;
    int former;

    add("{");

    foreach (m; mixed k; mixed v) {
	if (former) {
	    add(",");
	} else {
	    former++;
	}

	if (!stringp(k)) {
	    throw(Error.Generic(sprintf("(%O)%O is not a valid object key.\n",
			  _typeof(k), k)));
	}

	add(_string2json(k));
	add(":");
	add(serialize_pike(v));
    }

    add("}");
    
    return buf->get();
}
