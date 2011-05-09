object f;
mixed id;
function close_callback, read_callback;
string buf = "";
int(0..1) close_on_finish;
function query_address, close, is_open, errno;

void create(object f) {
    this_program::f = f;
    f->set_nonblocking(_read, _write, _close);
    query_address = f->query_address;
    close = f->close;
    is_open = f->is_open;
    errno = f->errno;
}

void set_id(mixed id) {
    this_program::id = id;
}

mixed query_id() {
    return id;
}

void set_close_callback(function cb) {
    close_callback = cb;
}

function query_close_callback() {
    return close_callback;
}

void set_read_callback(function cb) {
    read_callback = cb;
}

function query_read_callback() {
    return read_callback;
}

int write(string fmt, mixed ... extra) {
    int written;
    if (sizeof(extra)) fmt = sprintf(fmt, @extra);

    if (buf) {
	buf += fmt;
	return sizeof(fmt);
    }

    written = f->write(fmt);
    buf = fmt[written..];

    return sizeof(fmt);
}

void destroy() {
    if (f) {
	f->close();
	destruct(f);
    }
}

void close_when_finished() {
    close_on_finish = 1;
    if (!buf) _write(f->query_id());

}

mixed _read(mixed id, string data) {
    if (read_callback) return read_callback(this_program::id, data);
    return 0;
}

mixed _close(mixed id) {
    if (close_callback) return close_callback(this_program::id);
    return 0;
}

mixed _write(mixed id) {
    if (buf) {
	if (sizeof(buf)) {
	    int written = f->write(buf);
	    buf = buf[written..];
	} else {
	    buf = 0;
	}
    }
    if (!buf && close_on_finish) {
	if (is_open()) f->set_nonblocking(); // remove callbacks ==> kill cyclics
	close();
    }

    return 0;
}
