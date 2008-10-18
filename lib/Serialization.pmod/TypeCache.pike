mapping(program:mapping(mixed:object)) m = ([]);

void create() {
    set_weak_flag(m, Pike.WEAK);
}

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

    return 0;
}

// []= should not be used..!
