object type_cache = Serialization.default_type_cache;

void create(object o) {
//    werror("cache: %O\n", o);
    type_cache = o;
}

