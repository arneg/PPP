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

//! Mapping containing the current MMP state.
mapping variable_state = ([]);

string key;
mixed value;
int mod, lastmod;

int max_keylength = 0, max_valuelength = 0, max_datalength = 0, _length;

void augment(string key, mixed val) {
    
    if (arrayp(val)) {
	foreach (val, string t) {
	    augment(variable_state, key, t);
	}
    } else {
	// do the same with inpacket->vars too
	if (arrayp(variable_state[key])) {
	    variable_state[key] += ({ val });
	} else {
	    variable_state[key] = ({ variable_state[key], val });
	}
    }
}

void diminish(string key, mixed val) {
    if (arrayp(variable_state[key])) {
	variable_state[key] -= ({ val });
    } else if (has_index(variable_state, key)) {
	if (variable_state[key] == val)
	    m_delete(variable_state, key);
    }
}

//! @params conf
//! @ul 
//! 	@item "callback"
//! 		Callback to be called whenever a @[MMP.Packet] has been parsed.
//! 		Will be called with the @[MMP.Packet] object as the only argument.
//! 	@item "transform"
//! 		Callback to perform transformations on parsed values. Will be called like
//! 		@expr{transform(string key, mixed value)}.
//! @endul
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

//! Concatenates @expr{data} to the buffer and tries to parse. @expr{data} 
//! does not need to be a complete packet.
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
    switch (lastmod) {
    case '=':
	variable_state[key] = value;
	break;
    case '+':
	augment(key, value);
	break;
    case '-':
	diminish(key, value);
	break;
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
	    lastmod = mod;
	    mod = buffer[pos];
	    break;
	case '?':
	    _error("unimplemented modifier");
	case '.':
	    if (key) _error("non_empty");

	    if (sizeof(buffer) >= pos+2) {
		if (buffer[pos+1] == '\n') { // empty packet
		    search_pos = pos = pos+2;
		    callback(packet);
		    _reinit();
		    _parse();
		    return;
		} else _error("empty termination");
	    }
	    return;
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

