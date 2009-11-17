mapping m = ([]);
MMP.Utils.Queue queue = MMP.Utils.Queue();
int max; 

void create(int max) {
	this_program::max = max;
}

mixed `[](mixed key) {
	return m[key];
}

mixed `[]=(mixed key, mixed val) {
	queue->push(({ key, val }));
	// we have to remove overwritten entries, otherwise we will
	// probably delete something too early which has been there before.
	// so this is officially broken, but we will use this dildo in a 
	// absolutely safe fashion.
	m[key] = val;
	
	if (sizeof(m) > max) {
		[mixed oldkey, mixed oldval] = queue->shift();

		// this is bad, see above.
		if (has_index(m, oldkey) && m[oldkey] == oldval) {
			m_delete(m, oldkey);
		}
	}
}

int(0..1) _has_index(mixed key) {
	return has_index(m, key);
}

int _sizeof() {
	return sizeof(m);
}

Iterator _get_iterator() {
	return get_iterator(m);
}
