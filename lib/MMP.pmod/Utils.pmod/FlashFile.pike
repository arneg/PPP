// vim:syntax=lpc
inherit Stdio.File;

#define REQUEST	"<policy-file-request />\0"

object _policy;
function _read_cb, _write_cb;
string buf;
int read_done;

void switch_to_normal() {
    _policy = 0;

    ::set_read_callback(_read_cb);
    ::set_write_callback(_write_cb);

    if (buf && buf != "") {
	call_out(_read_cb, 0, query_id(), buf);
    }

    buf = 0;
    read_done = 1;
    _read_cb = _write_cb = 0;
}

// expects "<policy-file-request />\0"
void read_handshake(mixed id, string data) {
    if (!buf) {
	buf = data;
    } else {
	buf += data;
    }

    if (sizeof(buf) < sizeof(REQUEST)) {
	if (!has_prefix(REQUEST, buf)) {
	    switch_to_normal();
	}
    } else {
	if (!has_prefix(buf, REQUEST)) {
	    switch_to_normal();
	} else {
	    //send policy, when completed switch to normal
	    send_policy();
	}
    }
}

void send_policy() {
    buf = buf[sizeof(REQUEST)..]; 
    ::set_read_callback(_read_cb);
    read_done = 1;
    _read_cb = UNDEFINED;
    call_out(_read_cb, 0, query_id(), buf);

    buf = _policy->render_policy();
    ::set_write_callback(write_policy);
}

void write_policy() {
    int bytes = write(buf);

    if (bytes == -1) {
	// panic here!
	close();
    }

    if (bytes < sizeof(buf)) {
	buf = buf[bytes..];
    } else {
	_policy = UNDEFINED;
	buf = UNDEFINED;
	//::set_write_callback(_write_cb);
	switch_to_normal();
    }
}

void create(object policy) {
    _policy = policy;

    ::set_read_callback(read_handshake);
}

void set_read_callback(function(mixed:int) read_cb) {
    if (read_done) {
	::set_read_callback(read_cb);
    } else {
	_read_cb = read_cb;
    }
}

void set_write_callback(function(mixed:int) write_cb) {
    if (_policy) {
	_write_cb = write_cb;
    } else {
	::set_write_callback(write_cb);
    }
}

void set_nonblocking(mixed|void rcb,
		   mixed|void wcb,
		   mixed|void ccb,
		   mixed|void roobcb,
		   mixed|void woobcb) {
    if (rcb && !read_done) {
	_read_cb = rcb;
	rcb = read_handshake;
    }

    if (wcb && _policy) {
	_write_cb = wcb;
	wcb = UNDEFINED;
    }

    ::set_nonblocking(rcb, wcb, ccb, roobcb, woobcb);
}

