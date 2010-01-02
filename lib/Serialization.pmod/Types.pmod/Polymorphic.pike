// set of supported atom types
Serialization.AbbrevHash atypes = Serialization.AbbrevHash();
// set of supported pike type, either basetype() or object_program()
// we could think about supporting inheritance at some point
mapping ptypes = ([]);

void register_type(string|program ptype, string atype, object type) {
    if (!has_index(ptypes, ptype)) {
	ptypes[ptype] = ({ type });
    } else {
	ptypes[ptype] += ({ type });
    }

    array t = atypes[atype];

    if (t) {
	atypes[atype] += ({ type });
    } else {
	atypes[atype] = ({ type });
    }
}

void unregister_type(string|program ptype, string atype, object type) {
    if (has_index(ptypes, ptype)) {
		ptypes[ptype] -= ({ type });

		if (!sizeof(ptypes[ptype])) m_delete(ptypes, ptype);
    }

	array t;
	if (t = atypes[atype]) {
		t -= ({ type });

		if (!sizeof(t)) m_delete(atypes, atype);
		else atypes[atype] = t;
    }
}

int(0..1) can_decode(Serialization.Atom a) {
    array t;

    if (t = atypes[a->type]) foreach (t;; object type) {
		if (type->can_decode(a)) return 1;
    }

    return 0;
}

mixed decode(Serialization.Atom a) {
    array t;

    if (t = atypes[a->type]) foreach (t;; object type) {
		mixed err = catch {
			if (type->can_decode(a)) {
				return type->decode(a); 
			} else {
				werror("%O cannot decode %s\n", type, a->render());
			}
		};

		werror(describe_error(err));
    } else {
		error("No potential type for %s\n", a->type);
	}

    error("Cannot decode %O\n", a);
}

int(0..1) can_encode(mixed v) {
    mixed key = objectp(v) ? object_program(v) : basetype(v);

    array t;

    if (t = ptypes[key]) foreach (t;; object type) {
	    if (type->can_encode(v)) return 1;	
    }

    return 0;
}

Serialization.Atom encode(mixed v) {
    mixed key = objectp(v) ? object_program(v) : basetype(v);

    array t;

    if (t = ptypes[key]) {
	    foreach (t;; object type) {
		if (type->can_encode(v)) return type->encode(v);
	    }
    }
    
    error("Cannot encode %O\n", v);
}

string render_payload(Serialization.Atom atom) {
    return atom->signature->render_payload(atom);
}

MMP.Utils.StringBuilder render(mixed t, MMP.Utils.StringBuilder buf) {
    mixed key = objectp(t) ? object_program(t) : basetype(t);

    if (has_index(ptypes, key)) {
	    foreach (ptypes[key];; object type) {
		    if (type->can_encode(t)) return type->render(t, buf);
	    }
    }
    error("Cannot render %O\n", t);
}
