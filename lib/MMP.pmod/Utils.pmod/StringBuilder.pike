int entries = 0;
int size = 0;
#ifndef ARRAY_BUILDER
array head, tail;
#else
array data;
#endif

void create(string|void s) {
#ifdef ARRAY_BUILDER
	data = allocate(30);
#endif
    if (s) add(s);
}

int get_entries() {
    return entries;
}

#ifndef ARRAY_BUILDER
array _add(array structure, string|void s) {
    if (structure) {
		array current = structure;

		structure = allocate(3);
#ifdef TRACE_SOFT_MEMLEAKS
		structure[0] = MMP.Utils.Screamer();
#endif
		//structure[0] = current;
		//structure[1] = current[1];
		if (s) {
			structure[2] = s;
			size += sizeof(s);
		}
		current[1] = structure;
		entries++;

		return structure;
    } else {
		head = tail = structure = allocate(3);

#ifdef TRACE_SOFT_MEMLEAKS
		structure[0] = MMP.Utils.Screamer();
#endif
		//structure[0] = structure;
		//structure[1] = structure;
		if (s) {
			structure[2] = s;
			size += sizeof(s);
		}
		entries++;

		return structure;
    }
}
#endif

void set_node(mixed node, string s) {
#ifndef ARRAY_BUILDER
	if (node[2]) {
		size += sizeof(s) - sizeof(node[2]);
	} else size += sizeof(s);
	node[2] = s;
#else
	if (data[node]) {
	    size += sizeof(s) - sizeof(data[node]);
	} else size += sizeof(s);
	data[node] = s;
#endif
}

int|array add(string|void s) {
#ifndef ARRAY_BUILDER
    tail = _add(tail, s);
    return tail;
#else
	if (sizeof(data) <= entries) {
		data += allocate(30);
	}

	if (s) {
	    size += sizeof(s);
	}
	data[entries] = s;

	entries++;
	return entries-1;
#endif
}

string get() {
#ifndef ARRAY_BUILDER
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
#else
    string ret = data[0..entries-1] * "";
    entries = size = 0;
    return ret;
#endif
}

int length() {
	return size;
}

#if 0
int count_length(array node, array|void tail) {
    int len;

    if (!tail) tail = this_program::tail;

    for(;;node = node[1]) {
	if (stringp(node[2])) {
	    len += sizeof(node[2]);
	}

	if (node == tail) break;
    }

    return len;
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
#endif
