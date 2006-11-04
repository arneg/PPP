// vim:syntax=lpc

String.Buffer _sb;
function(string... : int) _add;
string _newline;

void create(object|mapping|array|string|int|float thing, String.Buffer|void sb,
	    string|void newline) {
    _sb = sb || String.Buffer();
    _add = _sb->add;
    _newline = newline || "\\n";

    _thing2json(thing);
}

void _thing2json(object|mapping|array|string|int|float thing) {
    if (stringp(thing)) {
	_string2json(thing);
    } else if (intp(thing)) {
	_int2json(thing);
    } else if (floatp(thing)) {
	_float2json(thing);
    } else if (mappingp(thing)) {
	_mapping2json(thing);
    } else if (arrayp(thing)) {
	_array2json(thing);
    } else {
	throw(Error.Generic(sprintf("Could not serialize %O, it's a %O, but I "
				    "can't handle " "that.\n",
				    thing, _typeof(thing))));
    }
}

void _string2json(string|object s) {
    _add("\"");

    foreach (s;; int c) {
	switch (c) {
	    case '\\':
	    case '"':
		_add("\\");
		_add(String.int2char(c));
		break;
	    case '\b':
		_add("\\b");
		break;
	    case '\f':
		_add("\\f");
		break;
	    case '\n':
		_add(_newline);
		break;
	    case '\r':
		_add("\\r");
		break;
	    case '\t':
		_add("\\t");
		break;
	    default:
		if (c < ' ') {
		    _add(sprintf("\\u%04x", c));
		} else {
		    _add(String.int2char(c));
		}

		break;
	}
    }

    _add("\"");
}

void _int2json(int|object thing) {
    if (zero_type(thing)) {
	_add("null");
    } else {
	_add((string)thing);
    }
}

void _float2json(float|object f) {
    string s = lower_case((string)f);

    if (!has_value(s, 'e') && has_value(s, '.')) {
	while (has_suffix(s, "0")) {
	    s = s[..sizeof(s) - 2];
	}

	_add(s);

	if (has_suffix(s, ".")) {
	    _add("0");
	}
    }
}

void _array2json(array|object a) {
    _add("[");

    foreach (a; int pos; mixed v) {
	if (pos) _add(",");

	_thing2json(v);
    }

    _add("]");
}

void _mapping2json(mapping|object m) {
    int former;

    _add("{");

    foreach (m; mixed k; mixed v) {
	if (former) {
	    _add(",");
	} else {
	    former++;
	}

	if (!stringp(k)) {
	    throw(Error.Generic(sprintf("(%O)%O is not a valid object key.\n",
			  _typeof(k), k)));
	}

	_string2json(k);
	_add(":");
	_thing2json(v);
    }

    _add("}");
}
