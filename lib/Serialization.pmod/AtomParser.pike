// vim:syntax=c
string type;
string action;
int bytes = UNDEFINED;
string|String.Buffer buf = "";

void reset(int bytes) {
    type = action = 0;
    this_program::bytes = UNDEFINED;

    if (bytes < sizeof(buf)) {
		buf = ([string]buf)[bytes..];
    } else if (bytes == sizeof(buf)) {
		buf = "";
    } else {
		error("bad reset()\n");
    }
}

void feed(string data) {
    buf += data;
}

int left() {
    return sizeof(buf);
}

int|.Atom parse(void|string data) {
    if (data) feed(data);

    if (!sizeof(buf)) return 0;

    if (!type) {
	if (buf[0] != '_') {
	    error("Broken Atom. Does not start with a type. (%O)", buf);
	}

	int pos = search(buf, ' ');

	if (pos == -1) {
	    // we may check here is something is wrong.. potentially
	    return 0;
	}
	
	type = ([string]buf)[0..pos-1];
	buf = ([string]buf)[pos+1..];

	if (-1 != (pos = search(type, ':'))) {
	    action = type[pos+1..];
	    type = type[0..pos-1];
	}
    }

    if (!bytes && zero_type(bytes)) {
	int pos = search(buf, ' ');

	if (pos == -1) {
	    // we could check here if there are chars in the buf
	    // that are not numbers.. and return an error 
	    return 0;
	}

	if (1 != sscanf(([string]buf)[0..pos-1], "%d", bytes)) {
	    throw(({ "Broken Atom. Cannot parse length.\n", backtrace() }));
	}

	buf = String.Buffer() + ([string]buf)[pos+1..];
    }

    if (bytes == 0) {
	object atom = .Atom(type, "", action);
	buf = (string)buf;
	reset(0);
	return atom;
    } else if (sizeof(buf) >= bytes) {
	buf = (string)buf;
	object atom = .Atom(type, ([string]buf)[0..bytes-1], action);
	reset(bytes);	
	return atom;
    }

    return 0;
}
