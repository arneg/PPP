// vim:syntax=lpc
// $Id: module.pmod,v 1.11 2006/11/04 16:30:56 el Exp $

mixed parse(string json, program|void objectb, program|void arrayb) {
#if 0
#if constant(Public)
# if constant(Public.Parser)
#  if constant(Public.Parser.JSON)
    if (!(objectb || arrayb)) {
	return Public.Parser.JSON.parse(json);
    }
#  endif
# endif
#endif
#endif

    return parse_pike(json, objectb, arrayb);
}

mixed parse_pike(string json, program|void objectb, program|void arrayb) {
    return .JSONTokener(json, objectb, arrayb)->nextObject();
}

String.Buffer serialize(object|mapping|array|string|int|float thing,
		String.Buffer|void sb, string|void newline) {
#if 0
#if constant(Public)
# if constant(Public.Parser)
#  if constant(Public.Parser.JSON)
    string res;

    res = Public.Parser.JSON.serialize(thing);
    if (newline) res = replace(res, "\n", newline);
    if (!sb) sb = String.Buffer(sizeof(res));
    sb->add(res);

    return sb;
#  endif
# endif
#endif
#endif

    return (newline) 
	    ? replace(serialize_pike(thing, sb), "\n", newline)
	    : serialize_pike(thing, sb);
}

String.Buffer serialize_pike(object|mapping|array|string|int|float thing,
		     String.Buffer|void sb) {
    int type;

    if (!sb) sb = String.Buffer();

    if (stringp(thing)) {
	_string2json(thing, sb);
    } else if (intp(thing)) {
	_int2json(thing, sb);
    } else if (floatp(thing)) {
	_float2json(thing, sb);
    } else if (mappingp(thing)) {
	_mapping2json(thing, sb);
    } else if (arrayp(thing)) {
	_array2json(thing, sb);
    } else {
	throw(Error.Generic(sprintf("Could not serialize %O, it's a %O, but I "
				    "can't handle " "that.\n",
				    thing, _typeof(thing))));
    }

    return sb;
}

void _string2json(string|object s, String.Buffer sb) {
    function(string... : int) add = sb->add;

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
}

void _int2json(int|object thing, String.Buffer sb) {
    if (zero_type(thing)) {
	sb->add("null");
    } else {
	sb->add((string)thing);
    }
}

void _float2json(float|object f, String.Buffer sb) {
    string s = lower_case((string)f);

    if (!has_value(s, 'e') && has_value(s, '.')) {
	while (has_suffix(s, "0")) {
	    s = s[..sizeof(s) - 2];
	}

	sb->add(s);

	if (has_suffix(s, ".")) {
	    sb->add("0");
	}
    }
}

void _array2json(array|object a, String.Buffer sb) {
    function(string... : int) add = sb->add;

    add("[");

    foreach (a; int pos; mixed v) {
	if (pos) add(",");

	serialize_pike(v, sb);
    }

    add("]");
}

void _mapping2json(mapping|object m, String.Buffer sb) {
    function(string... : int) add = sb->add;
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

	_string2json(k, sb);
	add(":");
	serialize_pike(v, sb);
    }

    add("}");
}
