mapping cache = ([ ]);
mixed o;

void create(mixed o) {
	this_program::o = o;
}

mixed get(string type, function f) {
    mixed t = cache[type];

    if (!t) {
	t = cache[type] = f(o);
    }

    return t;
}
