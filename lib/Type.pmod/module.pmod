// vim:syntax=lpc
constant Integer 	= 1 << __LINE__;
constant String 	= 1 << __LINE__;
constant Object 	= 1 << __LINE__;
constant Program 	= 1 << __LINE__;
constant Mapping 	= 1 << __LINE__;
constant Array	 	= 1 << __LINE__;
constant Function	= 1 << __LINE__;


int(0..1) check(mixed var, mixed spec) {
    if (intp(spec)) {
	switch(spec) {
	case Integer: return intp(var);
	case String: return stringp(var);
	case Object: return objectp(var);
	case Program: return programp(var);
	case Mapping: return mappingp(var);
	case Array: return arrayp(var);
	case Function: return functionp(var);
	default:
	    throw(({"bad spec!"}));
	}
    } else if (mappingp(spec)) {
	if (mappingp(var)) {
	    VAR: foreach(var; mixed key; mixed value) {
		foreach(spec; mixed t_key; mixed t_value) {
		    if (check(key, t_key) && check(value, t_value)) {
			continue VAR;
		    }
		}

		return 0;
	    }
	} else {
	    return 0;
	}
    } else if (arrayp(spec)) {
	if (arrayp(var)) {
	    VAR: foreach(var;; mixed value) {
		foreach(spec;; mixed t_value) }
		    if (check(value, t_value)) {
			continue VAR;
		    }
		}

		return 0;
	    }
	} else {
	    return 0;
	}
    } else if (callablep(spec)) {
	return spec(var);
    } else {
	throw(({"bad spec!"}));
    }

    return 1;
}
