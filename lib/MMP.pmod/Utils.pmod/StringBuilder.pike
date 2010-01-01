int entries;
array head, tail;

void create(string|void s) {
    if (s) add(s);
}

int get_entries() {
    return entries;
}

array _add(array structure, string|void s) {
    if (structure) {
	array current = structure;

	structure = allocate(3);
	structure[0] = current;
	structure[1] = current[1];
	structure[2] = s;
	current[1] = structure;
	entries++;

	return structure;
    } else {
	head = tail = structure = allocate(3);

	structure[0] = structure;
	structure[1] = structure;
	structure[2] = s;
	entries++;

	return structure;
    }
}

array add(string|void s) {
    array res = _add(tail, s);

    tail = tail[1];
    return res;
}

array add_pos(string|void s, int back) {
    array structure = tail, res;
    int was_head;

    for (back; back > 0; back--) {
	structure = structure[0];
    }

    if (structure[1] == head) {
	was_head = 1;
    }

    res = _add(structure, s);

    if (was_head) {
	head = structure[1];
    }

    return res;
}

string get() {
    if (head) {
	array tmp = allocate(entries);

	for (int i; i < entries; i++) {
	    tmp[i] = head[2];
	    head = head[1];
	}

	head = tail = entries = 0;
	return tmp * "";
    } else {
	return "";
    }
}

int count_length(array node, array|void tail) {
    int len;

    if (!tail) tail = this_program::tail;

    do {
	if (stringp(node[2])) {
	    len += sizeof(node[2]);
	}
    } while ((node = node[1]) != tail);

    return len;
}
