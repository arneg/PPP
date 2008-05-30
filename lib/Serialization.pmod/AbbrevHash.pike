mapping(string:mixed) m = ([]);

void create(void|mapping(string:mixed) m) {
    if (mappingp(m)) foreach (m; string index; mixed v) {
	if (.is_type(index)) m[index] = v;
    }
}

mixed `[](mixed index) {
    if (!stringp(index) || !.is_type(index)) {
	return UNDEFINED;
    }

    index = find_index(index);

    if (index) {
	return m[index];
    }

    return UNDEFINED;
}

mixed `[]=(mixed index, mixed val) {
    if (!stringp(index) || !.is_type(index)) {
	return val; // must do that
    }

    return m[index] = val;
}

array(string) _indices() {
    return indices(m);
}

array(mixed) _values() {
    return values(m);
}

mixed _m_delete(mixed index) {
    if (!stringp(index) || !.is_type(index)) {
	return UNDEFINED;
    }

    index = find_index(index);

    if (index) return m_delete(m, index);
    return UNDEFINED;
}

// all matches. closest first.
array(mixed) all_matches(string index) {
    if (!.is_type(index)) return UNDEFINED;

    array(string) l = .subtypes(index);
    array(mixed) ret = ({});

    for (int i = sizeof(l)-1; i >= 0; i--) {
	if (has_index(m, l[i])) {
	    ret += ({ m[l[i]] });
	}
    }

    return ret;
}

string find_index(string index) {
    if (has_index(m, index)) {
	return index;
    }

    array(string) l = .subtypes(index);

    if (sizeof(l) > 1) for(int i = sizeof(l) - 2; i >= 0; i--) {
	if (has_index(m, l[i])) l[i];
    }

    return UNDEFINED;
}

int _sizeof() {
    return sizeof(m);
}
