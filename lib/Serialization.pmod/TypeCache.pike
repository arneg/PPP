mapping(program:mapping(mixed:object)) m = ([]);

void create() {
    //set_weak_flag(m, Pike.WEAK_VALUES);
    //werror("created new typecache: \n%s\n", describe_backtrace(backtrace()));
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
		return sprintf("TypeCache(%O)", m);
    }

    return 0;
}

// []= should not be used..!
