// vim:syntax=c
string type;
int bytes = UNDEFINED;
int error = 0;
string|String.Buffer buf = "";

void reset() {
    type = 0;
    bytes = UNDEFINED;
    buf = "";
}

int|.Atom parse(string data) {
    buf += data;

    if (!type) {
	if (buf[0] != '_') {
	    error = 1;
	    return 0;
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
	    error = 2;
	    return 0;
	}

	buf = String.Buffer() + ([string]buf)[pos+1..];
    }

    if (sizeof(buf) == bytes) {
	object atom = .Atom(type, (string)buf);
	reset();
	return atom;
    } else if (sizeof(buf) > bytes) {
	error = 3;
    }

    return 0;
}
