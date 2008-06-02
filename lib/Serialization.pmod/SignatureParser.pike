mapping(string:mapping(mixed:object)) caches = ([]);
mapping(string:function|program) factories = ([]);

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
