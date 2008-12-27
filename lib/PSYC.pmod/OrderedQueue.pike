function smaller, is_ok;

array head;

void create(function smaller, function is_ok) {
    this_program::smaller = smaller;
    this_program::is_ok = is_ok;
}

mixed add(mixed m) {
    if (!head) {
	last = head = ({ m, 0 });
	return m;
    }

    array current = head;

    do {
	if (!smaller(head[0], m)) {
	    mixed tmp;
	    tmp = head[0];
	    head[0] = m;
	    head[1] = ({ tmp, head[1] });

	    return m;
	}
    } while (head = head[1]);

    last = last[1] = ({ m, 0 });

    return m;
}

// 0 0
// ->get()
// 1 3
// ->get()
// 1 2
// ->get()
// 0 1
// ->get()

mixed get() {
    if (head && is_ok(head[0])) {
	mixed ret = head[0];
	head = head[1];
	return ret;
    }
}
