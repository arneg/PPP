object type_cache;

void create(object o) {
    werror("cache: %O\n", o);
    type_cache = o;
}

// useless
mixed `->(string index) {
    werror("%O->%s\n", this, index);

    if (has_index(type_cache->factories, index)) {
	return Function.curry(type_cache->create_codec)(index);
    }

    return ::`->(index);
}

// auch nicht so tol
// beispiel
function List(mixed ... args) {
    type_cache[Types.OneTypedList][args]
    return type_cache->create_codec("List", @args);
}
