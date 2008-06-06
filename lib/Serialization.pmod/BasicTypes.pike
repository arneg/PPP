import Serialization.Types;

// make the compiler complain if no argument is given...
object List(object type, object ... args) {
    object o;
    if (sizeof(args)) {
	type = Or(@args);
    } 

    if (!(o = this->type_cache[OneTypedList][type])) {
	o = OneTypedList(type);
	this->type_cache[OneTypedList][type] = o;
    }

    return o;
}

object Mapping(object|mapping(object:object) m, object|void type2, object ... args) {
    object o;

    if (mappingp(m)) {
	if (objectp(type2)) {
	    throw(({ "Evil!", backtrace() }));
	}

	array args = allocate(sizeof(m)*2);

	foreach (sort(indices(m));int i; object ktype) {
	    args[i] = ktype;
	    args[i+1] = m[ktype];
	}

	return Mapping(@args);
    } else if (objectp(m) && objectp(type2)) {
	if (sizeof(args)) {
	    args = ({ m, type2 }) + args;

	    if (sizeof(args) & 1) {
		throw(({ "uh", backtrace() }));
	    }

	    object mangler = Serialization.Mangler(args);

	    if (!(o = this->type_cache[MultiTypedMapping][mangler])) {
		o = MultiTypedMapping(args);
		this->type_cache[MultiTypedMapping][mangler] = o;
	    }

	} else {
	    object mangler = Serialization.Mangler(({ m, type2 }));	

	    if (!(o = this->type_cache[OneTypedMapping][mangler])) {
		o = OneTypedMapping(m, type2);
		this->type_cache[OneTypedMapping][mangler] = o;
	    }
	}
    } else {
	throw(({ "uuuh", backtrace() }));
    }

    return o;
}

object Or(object type, object ... types) {
    object o;

    if (sizeof(types) == 0) {
	return type;
    }

    types = ({ type }) + types;
    object mangler = Serialization.Mangler(types); 

    if (!(o = this->type_cache[Serialization.Types.Or][mangler])) {
	o = Serialization.Types.Or(@types);
	this->type_cache[Serialization.Types.Or][mangler] = o;
    }
    
    return o;
}

object UOr(object type, object ... types) {
    return Or(@sort(({ type }) + types));
}

object String() {
    object o;

    if (!(o = this->type_cache[Serialization.Types.String][0])) {
	o = Serialization.Types.String();
	this->type_cache[Serialization.Types.String][0] = o;
    }

    return o;
}

object Int() {
    object o;

    if (!(o = this->type_cache[Serialization.Types.Int][0])) {
	o = Serialization.Types.Int();
	this->type_cache[Serialization.Types.Int][0] = o;
    }

    return o;
}
