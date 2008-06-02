mapping(program:mapping(mixed:object)) m = ([]);

mixed `[](mixed index) {
    if (programp(index)) {
	if (!has_index(m, index)) {
	    m[index] = ([]);
	}

	return m[index];
    }

    return UNDEFINED;
}

// []= should not be used..!
