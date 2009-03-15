// set of supported atom types
Serialization.AbbrevHash atypes = Serialization.AbbrevHash();
// set of supported pike type, either basetype() or object_program()
// we could think about supporting inheritance at some point
mapping ptypes = ([]);

mixed apply(Serialization.Atom a, mixed state, void|object misc) {
    multiset t;

    if (!misc) misc = .ApplyInfo();

    if (t = atypes[a->type]) foreach (t; object type;) {
	if (functionp(type->apply) && type->low_can_decode(a)) {
	    mixed ret = type->apply(a, state, misc);   
	    return ret;
	}
    }

    misc->faildepth = misc->depth;
    misc->failed = 1;
    return .UNSUPPORTED;
}

void register_type(string|program ptype, string atype, object type) {
    if (!has_index(ptypes, ptype)) {
	ptypes[ptype] = (< type >);
    } else {
	ptypes[ptype] += (< type >);
    }
    multiset t = atypes[atype];
    if (t) {
	t[type] = 1;
    } else {
	atypes[atype] = (< type >);
    }
}

void unregister_type(string|program ptype, string atype, object type) {
    if (has_index(ptypes, ptype)) {
	ptypes[ptype] -= (< type >);

	if (!sizeof(ptypes[ptype])) m_delete(ptypes, ptype);
    }
    multiset t;
    if (t = atypes[atype]) {
	while (t[type]) { t[type]--; }

	if (!sizeof(t)) m_delete(atypes, atype);
    }
}

int(0..1) can_decode(Serialization.Atom a) {
    multiset t;

    if (t = atypes[a->type]) foreach (t; object type;) {
	if (type->can_decode(a)) return 1;
    }

    return 0;
}

mixed decode(Serialization.Atom a) {
    multiset t;

    if (t = atypes[a->type]) foreach (t; object type;) {
	if (type->can_decode(a)) return type->decode(a); 
    }

    error("Cannot decode %O\n", a);
}

int(0..1) can_encode(mixed v) {
    mixed key = objectp(v) ? object_program(v) : basetype(v);

    multiset t;

    if (t = ptypes[key]) foreach (t; object type;) {
	if (type->can_encode(v)) return 1;	
    }

    return 0;
}

Serialization.Atom encode(mixed v) {
    mixed key = objectp(v) ? object_program(v) : basetype(v);

    multiset t;

    if (t = ptypes[key]) foreach (t; object type;) {
	if (type->can_encode(v)) return type->encode(v);
    }
    
    error("Cannot encode %O\n", v);
}
