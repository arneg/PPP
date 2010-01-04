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
    if (data) buf += data;
	int len = 0;
	string s;

    if (!sizeof(buf)) return 0;

    if (!bytes && zero_type(bytes)) {
		if (3 == sscanf(buf, "%[_a-zA-Z] %d %s", type, bytes, s)) {
			string temp;
			len = sizeof(buf) - sizeof(s);
			temp = buf;
			buf = s;
			s = temp;
		} else {
			bytes = UNDEFINED;
			return 0;
		}
    }

    if (bytes == 0) {
		object atom = .Atom(type, "", action);
		if (s) atom->done = s[0..len-1];
		buf = (string)buf;
		reset(0);
		return atom;
    } else if (sizeof(buf) >= bytes) {
		buf = (string)buf;
		object atom = .Atom(type, ([string]buf)[0..bytes-1], action);
		if (s) atom->done = s[0..len+bytes-1];
		
		reset(bytes);	
		return atom;
    }

    return 0;
}
