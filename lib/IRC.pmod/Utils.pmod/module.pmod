#include <debug.h>

class BufferedStream {
    inherit Stdio.File;

    int writeable, is_buffered, close_on_finish;
    function(void|mixed, void|string: void|mixed) _read_cb;
    function(mixed|void:mixed|void) _write_cb;
    function(void | mixed, void | int : void | mixed) _error_cb;
    mixed _close_cb;
    string linesep = "\n";
    MMP.Utils.Queue outqueue = MMP.Utils.Queue();
    String.Buffer unfinished = String.Buffer();

    void set_buffered_keep_callbacks() {
	if (is_buffered) {
	    return;
	}

	if (!::query_read_callback()) {
	    throw(({ "cannot switch to buffered mode without read callback\n",
		     backtrace() }));
	}

	if (!::query_close_callback()) {
	    throw(({ "cannot switch to buffered mode without close callback\n",
		     backtrace() }));
	}

	is_buffered = 1;

	_read_cb = ::query_read_callback();
	_close_cb = ::query_close_callback();
	_write_cb = ::query_write_callback();

	::set_nonblocking_keep_callbacks();
	::set_close_callback(close_cb);
	::set_read_callback(read_cb);
	::set_write_callback(write_cb);
    }

    void set_buffered(function(void|mixed, void|string: void|mixed) _read_cb_,
		      mixed _close_cb_,
		      void|function(void | mixed, void | int
				    : void | mixed) _error_cb_) {
	if (!_read_cb_) {
	    throw(({ "cannot switch to buffered mode without read callback\n",
		     backtrace() }));
	}

	if (!_close_cb_) {
	    throw(({ "cannot switch to buffered mode without close callback\n",
		     backtrace() }));
	}

	is_buffered = 1;

	_read_cb = _read_cb_;
	_close_cb = _close_cb_;
	_error_cb = _error_cb_;
	_write_cb = 0;

	::set_nonblocking();
	::set_close_callback(close_cb);
	::set_read_callback(read_cb);
	::set_write_callback(write_cb);
    }

    // this is static even though i don't think access control is needed in OOP
    // usually, because set_unbuffered_keep_callbacks() looks quite invitingly
    // in an environment also containing  set_nonblocking_keep_callbacks(),
    // set_blocking_keep_callbacks() and set_buffered_keep_callbacks() but
    // really shouldn't be called from outside this object.
    static void set_unbuffered_keep_callbacks() {
	function(void | mixed, void | int : void | mixed) t;

	if (!is_buffered) {
	    return;
	}

	::set_read_callback(_read_cb);
	::set_close_callback(_close_cb);
	::set_write_callback(_write_cb);

	t = _error_cb;

	set_unbuffered();

	_error_cb = t;
    }

    // static for the same reason as set_unbuffered_keep_callbacks.
    static void set_unbuffered() {
	_error_cb = 0;

	if (!is_buffered) {
	    return;
	}

	if (sizeof(unfinished)) {
	    call_out(_read_cb, 0, query_id(), unfinished->get());
	}

	is_buffered = _read_cb = _close_cb = _write_cb = 0;
    }

    mixed query_close_callback() {
	if (is_buffered) {
	    return _close_cb;
	} else {
	    return ::query_close_callback();
	}
    }

    void set_close_callback(mixed c) {
	if (is_buffered) {
	    if (!c) {
		throw(({ "You supplied zero to "
		         "IRC.Utils.BufferedStream::set_close_callback "
			 "while beeing in buffered mode.\n",
			 backtrace() }));
	    } else {
		_close_cb = c;
	    }
	} else {
	    ::set_close_callback(c);
	}
    }

    function(void|mixed, void|string: void|mixed) query_read_callback() {
	if (is_buffered) {
	    return _read_cb;
	} else {
	    return ::query_read_callback();
	}
    }

    void set_read_callback(function(void|mixed, void|string: void|mixed) c) {
	if (is_buffered) {
	    if (!c) {
		throw(({ "You supplied zero to "
		         "IRC.Utils.BufferedStream::set_read_callback "
			 "while beeing in buffered mode.\n",
			 backtrace() }));
	    } else {
		_read_cb = c;
	    }
	} else {
	    ::set_read_callback(c);
	}
    }

    function(mixed|void:mixed|void) query_write_callback() {
	if (is_buffered) {
	    return _write_cb;
	} else {
	    return ::query_write_callback();
	}
    }

    void set_write_callback(function(mixed|void:mixed|void) c) {
	if (is_buffered) {
	    _write_cb = c;
	} else {
	    ::set_write_callback(c);
	}
    }

    void set_error_callback(function(void | mixed, void | int : void | mixed) c) {
	_error_cb = c;
    }

    function(void | mixed, void | int : void | mixed) query_error_callback() {
	return _error_cb;
    }

    void set_blocking() {
	set_unbuffered();
	::set_blocking();
    }

    void set_blocking_keep_callbacks() {
	set_unbuffered_keep_callbacks();
	::set_blocking_keep_callbacks();
    }

    void set_nonblocking(mixed|void rcb, mixed|void wcb, mixed|void ccb,
			 mixed|void roobcb, mixed|void woobcb) {
	set_unbuffered();
	::set_nonblocking(rcb, wcb, ccb, roobcb, woobcb);
    }

    void set_nonblocking_keep_callbacks() {
	set_unbuffered_keep_callbacks();
	::set_nonblocking_keep_callbacks();
    }

    int async_connect(string host, int|string port,
		      function(int, mixed ...: void) callback,
		      mixed ... args) {
	int res;

	if (sizeof(unfinished)) {
	    call_out(_read_cb, 0, query_id(), unfinished->get());
	}

	res = ::async_connect(host, port, callback, @args);

	if (res) {
	    set_unbuffered();
	}

	return res;
    }

    int assign(BufferedStream|Stdio.File|Stdio.Fd f) {
	int res;

	res = ::assign(f);

	if (Program.inherits(object_program(f), this_program)) {
	    _error_cb = [function(void | mixed, void | int : void | mixed)]f->_error_cb;

	    if (f->is_buffered) {
		set_buffered_keep_callbacks();
	    }
	}

	return res;
    }

    BufferedStream dup() {
	BufferedStream n = BufferedStream();
	n->assign(this);

	return n;
    }

    void close_when_finished() {
	close_on_finish = 1;
    }

    string read(int|void len, int(0..1)|void not_all) {
	if (sizeof(unfinished) > len) {
	    string res = unfinished->get();

	    unfinished->add(res[len..]);
	    return res[..len - 1];
	} else if (sizeof(unfinished)) {
	    return unfinished->get();
	} else {
	    return ::read(len, not_all);
	}
    }

    // do not unread strings containig newlines if you expect to get
    // _only_ lines passed to your readcb etc.
    void unread(string data) {
	string tmp = unfinished->get();

	unfinished->add(data);
	unfinished->add(tmp);
    }

    int peek(int|float|void timeout) {
	if (sizeof(unfinished)) {
	    return 1;
	} else {
	    return ::peek(timeout);
	}
    }

    int write_cb(mixed id) {
	P4(("IRC.Utils.BufferedStream", "write_cb called\n"))

	writeable = 1;

	if (!outqueue->isEmpty()) {
	    do_write();
	}

	return 0;
    }

    int write(array(string)|string what, mixed ... fmt) {
	if (arrayp(what)) {
	    what = what * "";
	}

	if (sizeof(fmt)) {
	    outqueue->push(what = sprintf([string]what, @fmt));
	} else {
	    outqueue->push(what);
	}

	if (writeable) {
	    do_write();
	}

	return sizeof(what); // that's kind of a lie, as for Stdio.File it means
			     // "the number of bytes that were actually written"
			     // which.. aint' true for us.
			     // so our meaning is:
			     // "number of bytes BufferedStream takes care of."
			     //
			     // i really hope that that isn't inconsistent with
			     // Stdio.File, because i could have had it way
			     // easier with a class not extending Stdio.File
			     // but providing basically the same functionality.
    }

    void do_write() {
	string data;
	int written;

	writeable = 0;
	data = [string]outqueue->shift();
	written = ::write(data);

	if (written < 0) {
	    outqueue->unshift(data);

	    if (_error_cb) {
		_error_cb(query_id(), written);
	    }
	} else if (written < sizeof(data)) {
	    outqueue->unshift(data[written..]);
	} else if (close_on_finish && outqueue->isEmpty()) {
	    close();
	    close_on_finish = 0;
	}
    }

    int close_cb(mixed id) {
	P3(("IRC.Utils.BufferedStream", "close_cb called\n"))
	
	if (sizeof(unfinished)) {
	    _read_cb(id, unfinished->get());
	}

	_close_cb(id);

	return 0;
    }

    int read_cb(mixed id, string data) {
	array(string) lines;

	P4(("IRC.Utils.BufferedStream", "read_cb(%O)\n", data))

	lines = data / linesep;

	for (int i = 0;; i++) {
	    unfinished->add(lines[i]);

	    if (i + 1 < sizeof(lines)) {
		unfinished->add(linesep);
		_read_cb(id, unfinished->get());
	    } else {
		break;
	    }
	}

	return 0;
    }
}
