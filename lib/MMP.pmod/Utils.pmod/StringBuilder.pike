int len, entries;
array head, tail;

void create(string|void s) {
    if (s) add(s);
}

int get_length() {
    return len;
}

int get_entries() {
    return entries;
}

void _add(array structure, string s) {
    if (structure) {
	array current = structure;

	structure = allocate(3);
	structure[0] = current;
	structure[1] = current[1];
	structure[2] = s;
	current[1] = structure;
    } else {
	head = tail = structure = allocate(3);

	structure[0] = structure;
	structure[1] = structure;
	structure[2] = s;
    }

    len += sizeof(s);
    entries++;
}

void add(string s) {
    _add(tail, s);
    tail = tail[1];
}

void add_pos(string s, int back) {
    array structure = tail;
    int was_head;

    for (back; back > 0; back--) {
	structure = structure[0];
    }

    if (structure[1] == head) {
	was_head = 1;
    }

    _add(structure, s);

    if (was_head) {
	head = structure[1];
    }
}

string get() {
    if (head) {
	array tmp = allocate(entries);

	for (int i; i < entries; i++) {
	    tmp[i] = head[2];
	    head = head[1];
	}

	write("tmp: %O\n", tmp);
	head = tail = len = entries = 0;
	return tmp * "";
    } else {
	return "";
    }
}
