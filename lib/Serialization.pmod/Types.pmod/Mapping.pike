int(0..1) has_action(string action) {
    switch (action) {
    case "_add":
    case "_sub":
    case "_index":
	return 1;
    }
}

mapping _add(mapping state, mapping b) {
    if (!state && zerotype(state)) {
	return b;
    }
    return state + b; 
}

mapping _sub(mapping state, mapping b) {
    return state - b;
}

mapping _index(mapping state, mixed index) {
    if (has_index(state, index)) {
	return state[index];
    }

    error("_index on an entry that does not exist.\n");
}
