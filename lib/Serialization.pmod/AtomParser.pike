// vim:syntax=c
string type;
int bytes = UNDEFINED;
int error = 0;
string|String.Buffer buf = "";

void reset(int bytes) {
    type = 0;
    this_program::bytes = UNDEFINED;

    if (bytes < sizeof(buf)) {
	buf = ([string]buf)[bytes..];
    } else if (bytes == sizeof(buf)) {
	buf = "";
    } else {
	throw(({ "bad reset()\n", backtrace() }));
    }
}

void feed(string data) {
    buf += data;
}

int left() {
    return sizeof(buf);
}

array(.Atom) parse_all() {
    array(.Atom) ret = ({});
    .Atom t;

    while (t = parse()) {
	ret += ({ t });
    }

    return ret;
}

int|.Atom parse(void|string data) {
    if (data) feed(data);

    if (!sizeof(buf)) return 0;

    if (!type) {
	if (buf[0] != '_') {
	    throw(({ "Broken Atom. Does not start with a type.\n", backtrace() }));
	}

	int pos = search(buf, ' ');

	if (pos == -1) {
	    // we may check here is something is wrong.. potentially
	    return 0;
	}
	
	type = ([string]buf)[0..pos-1];
	buf = ([string]buf)[pos+1..];
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
	object atom = .Atom(type, "");
	buf = (string)buf;
	reset(0);
	return atom;
    } else if (sizeof(buf) >= bytes) {
	buf = (string)buf;
	object atom = .Atom(type, ([string]buf)[0..bytes-1]);
	reset(bytes);	
	return atom;
    }

    return 0;
}
