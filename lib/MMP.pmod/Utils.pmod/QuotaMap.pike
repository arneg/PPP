#define NEXT(x)	(x[0])
#define PREV(x)	(x[1])
#define KEY(x) (x[2])
#define DATA(x)	(x[3])

mapping(mixed:array) m = ([]);
array|int head, tail;
int max, size;

void create(int(1..) max) {
	this_program::max = max;
}

mixed `[](mixed key) {
	array n = m[key];
	return n ? DATA(n) : n;
}

void set_max(int n) {
    while (size > n) {
	m_delete(this, KEY(head));
    }

    max = n;
}

void remove(array n) {
	if (n != tail) PREV(NEXT(n)) = PREV(n);
	else tail = PREV(n);
	if (n != head) NEXT(PREV(n)) = NEXT(n);
	else head = NEXT(n);
	size--;
}

mixed `[]=(mixed key, mixed val) {
	array n;

	if (has_index(m, key)) {
		n = m[key];

		if (n != tail) {
			remove(n);
			NEXT(tail) = n;
			PREV(n) = tail;
			NEXT(n) = 0;
			tail = n;
		}

	} else {
		if (size) {
			n = allocate(4);
			PREV(n) = tail;
			tail = NEXT(tail) = n;
			
		} else {
			head = tail = allocate(4);
		}

		size++;

		KEY(tail) = key;
		m[key] = tail;


		if (size > max) {
			m_delete(m, KEY(head));
		}
	}

	DATA(tail) = val;
	
	return val;
}

mixed _m_delete(mixed key) {
	array n = m[key];

	if (n) {
		remove(n);	
		m_delete(m, key);
		return DATA(n);
	} else {
		return n;
	}
}

int(0..1) _has_index(mixed key) {
	return has_index(m, key);
}

int _sizeof() {
	return size;
}

array(mixed) _indices() {
    return indices(m);
}

array(mixed) _values() {
    array(mixed) ret = allocate(sizeof(m));
    foreach (m; int i; array a) {
	ret[i] = DATA(a);
    }
    return ret;
}

string _sprintf(int type) {
	string ret = "";
	if (type == 'O') {
		array n = head;

		do {
			ret += sprintf("( %O -> %O).", KEY(n), DATA(n));	
		} while ((n = NEXT(n)));

		return ret;
	}

	return 0;
}

Iterator _get_iterator() {
	return get_iterator(m);
}
