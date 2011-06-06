
object generate_default_type(array|string type, void|mapping overwrites) {
    // mapping(int:string|int)|array(mapping|
    array a = stringp(type) ? Parser.Pike.group(Parser.Pike.split(type)) : type;
    array b = ({});

OUTER: for (int i = 0; i < sizeof(a); i++) {
	string|array type = a[i];
	object sig;
	if (stringp(type)) {
	    type = String.trim_all_whites(type);
	}
	if (overwrites && overwrites[type]) {
	    sig = overwrites[type];
	} else switch (type) {
	case "\n":
	case "":
	case "|": continue OUTER;
	case "array":
	    if (!arrayp(a[i+1])) break;
	    sig = .Types.OneTypedList(generate_default_type(a[i+1][1..<1], overwrites));
	    i++;
	    break;
	case "mapping":
	    if (!arrayp(a[i+1])) break;
	    int pos = search(a[i+1], ":");
	    if (pos != -1) {
		sig = .Types.OneTypedMapping(generate_default_type(a[i+1][1..pos-1], overwrites),
					     generate_default_type(a[i+1][pos+1..<1], overwrites));
		i++;
	     }
	    break;
	case "string":
	    sig = .Types.String();
	    break;
	case "int":
	    sig = .Types.Int();
	    break;
	}
	if (sig) b += ({ sig });
	else error("Cannot generate parser for %O\n", type);
    }

    if (sizeof(b) > 1) {
	return .Types.Or(@b);
    } else if (sizeof(b)) {
	return b[0];
    } 
    error("Could not generate parser for %O\n", type);
}

class Resolver(mapping symbols) {
    mixed resolv(string idx) {
	return has_index(symbols, idx) ? symbols[idx] : master()->resolv(idx);
    }
}

string get_type(object o, string fname) {
    program p = compile_string(sprintf("string get_type(___prog o) { return sprintf(\"%%O\", typeof(o->%s)); }", fname), "-",
			       Resolver(([ "___prog" : object_program(o), "`->" : (has_index(o, "`->") ? `[] : `->) ])));
    return p()->get_type(o);
}

object generate_struct(object o, string type, void|function helper, void|mapping overwrites) {
    array(string) a = indices(o) - indices(object_program(o));
    mapping m = ([]);

    function lookup = has_value(a, "`->") ? `[] : `->;

    foreach (a;; string symbol) {
	if (functionp(lookup(o, symbol))) {
	    continue;
	}

	if (helper) {
	    mixed v =  helper(o, symbol);
	    if (v == -1) {
		continue;
	    } else if (v) {
		m[symbol] = v;
		continue;
	    }
	}

	werror("symbol: %s %s\n", get_type(o, symbol), symbol);
	m[symbol] = generate_default_type(get_type(o, symbol), overwrites);
    }

    return .Types.Struct(type, m, object_program(o));
}

object generate_structs(mapping m, void|function helper, void|mapping overwrites) {
    object p = Serialization.Types.Polymorphic();
    foreach (m; string type; object o) {
	p->register_type(object_program(o), type, generate_struct(o, type, helper, overwrites));
    }
    return p;
}
