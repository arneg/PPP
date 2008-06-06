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

object Mapping(array(object) ... args) {
    // lets say, the order determines what is checked first.
    // 
}

object OOr(object types, object ... types) {
    object o;

    if (sizeof(types) == 0) {
	return type;
    }

    types = ({ type }) + args;
    object mangler = Serialization.Mangler(types); 

    if (!(o = this->type_cache[Serialization.Types.Or][mangler])) {
	o = Serialization.Types.Or(@types);
	this->type_cache[Serialization.Types.Or][mangler] = o;
    }
    
    return o;
}

object Or(object type, object ... types) {
    return OOr(sort(({ type }) + types));
}
