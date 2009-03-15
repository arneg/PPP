
void ok(int i) {
    if (!i) error("Test failed.\n");
}

void test_object(object o) {
    if (has_index(o, "init")) {
	o->init();
    }

    foreach (indices(o);;string key) {
	if (has_prefix(key, "test_")) {
	    mixed err = catch {
		`->(o, key)();
	    };
	    if (err) {
		werror("test %s failed: %O\n", key[5..], err);
	    }
	}
    }
}
