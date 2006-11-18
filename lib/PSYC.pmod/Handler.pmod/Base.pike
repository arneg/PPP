// vim:syntax=lpc
// probably the most efficient/bugfree class in the whole program
//

object uni;

// we tried optional, but that doesn't work - might be a bug, we'll ask the
// pikers soon. in the meantime, we'll use static.
static void create(object o) {
    uni = o;
}

mixed|MMP.Uniform string2uniform(array|mapping|multiset|MMP.Uniform u, void|int type) {

    if (stringp(u)) {
	return uni->server->get_uniform(u);
    } else if (arrayp(u)) {
	array new = allocate(sizeof(u));

	foreach (u;int i;mixed v) {
	    new[i] = string2uniform(v);
	}

	return new;
    } else if (mappingp(u)) {
	mapping new = ([ ]);

	foreach (u; mixed key; mixed value) {
	    new[ (type & 1) ? string2uniform(key) : key ] =
		(type & 2 || !type) ? string2uniform(value) : value;
	}

	return new;
    } else if (multisetp(u)) {
	multiset new = (< >);

	foreach (u; mixed key;) {
	    new[string2uniform(key)] = 1;
	}

	return new;
    }
    return u;
}
