mapping(string:mapping(mixed:object)) caches = ([]);
mapping(string:function|program) factories = ([]);

class OneTypedList {
    object type;
    // TODO:: inherit Something; // providing `|, ...

    void create(object type) {
	this_program::type = type;
    }

    array decode(.Atom a) {
	if (!low_can_parse(a)) ERROR();

	array list = parse_atoms...

	foreach (list;int i;.Atom item) {
	    // vielleicht macht das type bessser selber
	    if (!type->low_can_parse(item)) ERROR(); 

	    list[i] = type->decode(item);
	}

	return list;
    }

    int(0..1) low_can_parse(.Atom a) {
	return .is_subtype_of(a->type, "_list");
    }
}

class Mangler {
    array container;                                                                                         
    void create(array a) {
	container = a;
    }

    int(0..1) `==(mixed arg) {
        if (objectp(arg)) {                                          
            if (Program.inherits(object_program(arg), this_program)) {
                return equal(container, arg->container);
            }
        }
    }
    
    // TODO:: more efficient hash function!
    int __hash() {
        if (!container) {
            return hash_value(container);
        }
                                                               
        int ret;                                                     
        foreach (container;int i;mixed val) {
            int t = hash_value(val);
            ret ^= (t * (i + 1)) % Int.NATIVE_MAX;
        }
        return ret;
    }
}


void register_type(string name, program|function factory) {
    factories[name] = factory;
    caches[name] = ([]);
}

object create_codec(string codec, mixed ... spec) {
    mixed m = (sizeof(spec) <= 1) ? spec : Mangler(spec);
    
    if (!has_index(caches[codec], m)) {
	return caches[codec][m] = factories[codec](@spec);
    }

    return caches[codec][m];
}

// das muss nicht sein.. allerdings muessen die objekte mit signatures sowas 
// aehnliches inheriten..
mixed `->(string index) {
    if (index == "register_type") {
	return register_type;
    }

    if (has_index(factories, index)) {
	return Function.curry(create_codec)(index);
    }
}
