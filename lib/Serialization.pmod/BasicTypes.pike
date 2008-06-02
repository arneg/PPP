import Serialization.Types;

// make the compiler complain if no argument is given...
object List(object type, object ... args) {
    object o;
    if (sizeof(args) == 0) {
	if (!(o = this->type_cache[OneTypedList][type])) {
	    o = OneTypedList(type);
	    this->type_cache[OneTypedList][type] = o;
	}
    } else {
	args = sort(({ type }) + args); // order does not matter!
	object mangler = Mangler(args); 
	
	if (!(o = this->type_cache[MultiTypedList][mangler])) {
	    o = MultiTypedList(@args);
	    this->type_cache[MultiTypedList][mangler] = o;
	}
    }

    return o;
}

object Mapping(array(object) ... args) {
    // lets say, the order determines what is checked first.
    // 
}
