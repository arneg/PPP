inherit .OneTypedList;

program|function constructor;

void create(program|function constructor, object type) {
    //::create(Serialization.Types.Range(type, type));
    this_program::constructor = constructor;
    ::create(master()->resolv("SyncDB.Serialization.Range")(type));
    this_program::type = "_rangeset";
}

object decode(Serialization.Atom atom) {
    array l = ::decode(atom);
    
    object set = ADT.CritBit.RangeSet(constructor());
    foreach (l;; object range) {
	set[range] = 1;
    }
    return set;
}

int(0..1) can_encode(mixed o) {
    werror(">> can_encode?(%O(%O))\n", o, object_program(o));
    return (objectp(o) && 
	    Program.inherits(object_program(o), ADT.CritBit.RangeSet));
}

Serialization.Atom encode(object o) {
    return ::encode(o->ranges());
}
