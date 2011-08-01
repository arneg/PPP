inherit .OneTypedMapping;

program|function constructor;

void create(program|function constructor, object key, object value) {
    this_program::constructor = constructor;
    ::create(key, value);
}

object decode(Serialization.Atom atom) {
    return constructor(::decode(atom));
}

object encode(object tree) {
    return ::encode((mapping)tree);
}

int(0..1) can_encode(mixed o) {
    if (funtionp(constructor)) return 1;
    if (programp(constructor) && objectp(o) 
    && Program.inherits(object_program(o), constructor))
	return 1;
    return ::can_encode(o);
}
