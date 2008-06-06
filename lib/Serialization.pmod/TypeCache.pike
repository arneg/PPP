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

string _sprintf(int c) {
    if (c == 'O') {
	return sprintf("TypeCache(%O)\n", m);
    }

    return "";
}

// []= should not be used..!
