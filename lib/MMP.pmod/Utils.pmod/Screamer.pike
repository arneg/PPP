void destroy(int reason) {
    switch (reason) {
	case Object.DESTRUCT_GC:
	    werror("%O(%O) is doomed.\n", this, object_program(this));
    }
}
