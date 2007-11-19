// vim:syntax=lpc
constant STATE_DONE = 1;
constant STATE_HEADER = 2;
constant STATE_DATA = 4;
constant STATE_LENGTH = 8;
constant STATE_VALUE = 16;
constant STATE_LIST = 32;

int state, pos, search_pos;
string buffer;
MMP.Packet packet;
function callback, transform;
mapping variable_state = ([]);

string key;
mixed value;
int mod, lastmod;

int max_keylength = 0, max_valuelength = 0, max_datalength = 0, _length;

void create(mapping conf) {
    
    callback = conf["callback"];
    transform = conf["transform"];

    _reinit();
}

mixed _transform(string key, mixed value) {
    if (key == "_length") {
	return (int) value;
    }

    if (callablep(transform)) {
	return transform(key, value);
    }

    return value;
}

void _reinit() {
    packet = .Packet(0, copy_value(variable_state));

    state = STATE_HEADER;
    _length = UNDEFINED;

    if (stringp(buffer)) {
	if (pos == sizeof(buffer)) {
	    buffer = 0;
	} else {
	    buffer = buffer[pos..];
	}
	pos = search_pos = 0;
    }
}

void _error(string reason) {
    throw(({ reason+"\n", backtrace() }));
}

void parse(string data) {

    if (stringp(buffer)) {
	if (pos == sizeof(buffer)) {
	    buffer = data;
	} else if (pos > 0 && pos < sizeof(buffer)) {
	    buffer = buffer[pos..];
	}

	buffer += data;
    } else {
	buffer = data;
    }

    pos = 0;
    search_pos = 0;

    _parse();
}

void _finish_var() {
    value = _transform(key, value);
    if (key == "_length") _length = value;
    if (lastmod == '=') {
	variable_state[key] = value;
    }
    packet->vars[key] = value;
    key = 0;
    value = "";
}

void _parse() {
    if (stringp(buffer) && pos <= sizeof(buffer)-1) switch (state) {
    case STATE_HEADER: {
	if (buffer[pos] == '\t') { // continuation
	    if (!key)
		_error("continuation");
	    state = STATE_VALUE;
	    search_pos = ++pos;
	    value += "\n";
	    _parse();
	    return;
	}

	switch (buffer[pos]) {
	case '\n':
	    lastmod = mod;
	    if (key) _finish_var();
	    state = STATE_DATA;
	    search_pos = ++pos;
	    _parse();
	    return;
	case ':':
	case '=':
	case '+':
	case '-':
	case '?':
	    lastmod = mod;
	    mod = buffer[pos];
	    break;
	default:
	    _error("modifier");
	}
	pos = ++search_pos;
	int n = search(buffer, "\t", search_pos);

	if (n == -1) {
	    if (max_keylength && sizeof(buffer)-pos > max_keylength)
		_error("max_keylength");

	    search_pos = sizeof(buffer);
	    return;
	} else if (max_keylength && max_keylength < n-pos) {
	    _error("max_keylength");
	} else if (n == pos) { // list
	    if (lastmod != mod)
		_error("list");
	    search_pos = ++pos;
	    state = STATE_LIST;
	    _parse();
	    return;
	}

	if (key) _finish_var();

	key = buffer[pos .. n-1];
	pos = search_pos = n+1;
	state = STATE_VALUE;
	value = "";
    }
    case STATE_VALUE: {
	int n = search(buffer, "\n", search_pos);

	if (n == -1) {
	    if (max_valuelength && sizeof(buffer)-pos > max_valuelength)
		_error("max_valuelength");
	    
	    search_pos = sizeof(buffer);
	    return;
	} else if (max_valuelength && max_valuelength < n-pos) { 
	    _error("max_valuelength");
	}

	if (pos != n) 
	    value += buffer[pos .. n-1];
	pos = search_pos = n+1;
	state = STATE_HEADER;
	_parse();
	return;
    }
    case STATE_LIST: {
	int n = search(buffer, "\n", search_pos);

	if (n == -1) {
	    if (max_valuelength && sizeof(buffer)-pos > max_valuelength)
		_error("max_valuelength");

	    search_pos = sizeof(buffer);
	    return;
	} else if (max_valuelength  && max_valuelength < n-pos) {
	    _error("max_valuelength");
	}

	if (!arrayp(value)) value = ({ value });

	string temp;
	if (n == pos) {
	    temp = "";
	} else {
	    temp = buffer[pos .. n-1];
	}

	value += ({ temp });
	pos = search_pos = n+1;
	state = STATE_HEADER;
	_parse();
	return;
    }
    case STATE_DATA: {
	int n;
	if (zero_type(_length)) {
	    n = search(buffer, "\n.\n", search_pos);

	    if (n == -1) {
		search_pos = sizeof(buffer);
		
		if (max_datalength && sizeof(buffer)-pos > max_datalength)
		    _error("max_datalength");

		return;
	    }

	} else {
	    n = pos + _length;
	    werror("sizeof: %d\npos: %d\nstop: %d\n", sizeof(buffer), pos, n);
	    werror("data: %O\n", buffer[pos..]);

	    if (sizeof(buffer) < n+3) {
		return;
	    }

	    if (buffer[n .. n+2] != "\n.\n") {
		_error("terminated");
	    }
	}
	if (n > pos)
	    packet->data = buffer[pos .. n-1];
	else 
	    packet->data = "";

	search_pos = pos = n+3;
	callback(packet);
	_reinit();
	_parse();
	return;
    }
    }
}

