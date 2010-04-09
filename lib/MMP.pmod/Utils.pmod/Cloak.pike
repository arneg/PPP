mapping cache = ([ ]);
mixed o;

void create(mixed o) {
	this_program::o = o;
}

mixed get(void|string type, void|function f) {
    if (!type) return o;

    mixed t = cache[type];

    if (!t) {
	t = cache[type] = f(o);
    }

    return t;
}
