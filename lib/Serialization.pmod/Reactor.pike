mapping(program|int:string) program2type = ([]);
// type -> mapping(program->transform)
.AbbrevHash decoders = .AbbrevHash();
.AbbrevHash encoders = .AbbrevHash();
// type ¯> program|int
.AbbrevHash type2program = .AbbrevHash();

void register_fuse(string type, int|program ptype, function f) {
    if (!has_index(encoders->m, type)) {
	encoders[type] = ([ ptype : f ]);
    } else {
	encoders[type][ptype] = f;
    }
}

void register_fission(string type, int|program ptype, function f) {
    if (!has_index(decoders->m, type)) {
	decoders[type] = ([ ptype : f ]);
    } else {
	decoders[type][ptype] = f;
    }
}

mixed fission(.Atom a, void|int|program as) {
    if (as) { 
	array(mapping) t = filter(decoders->all_matches(a->type), has_index, as);

	if (sizeof(t)) {
	    return t[0][as](a, as, this);
	}

	return UNDEFINED;
    }

    // not sure if good!
    // default could be the first transform added for a particular type
    if (as = type2program[a->type]) {
	return fission(a, as); 
    }

    return UNDEFINED;
}

.Atom fuse(mixed a, void|string type) {
    int|program ptype = .to_type(a);

    if (!ptype) return UNDEFINED;
    werror("type ok.");

    if (!type) {
	type = program2type[ptype];
    }

    if (type) {
	array(mapping) t = filter(encoders->all_matches(type), has_index, ptype);

	if (sizeof(t)) {
	    return t[0][ptype](a, type, this);
	}
	werror("no encoder.");
    }
    werror("no _type");

    return UNDEFINED;
}

