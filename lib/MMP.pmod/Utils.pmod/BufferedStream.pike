    inherit Stdio.File;

    int will_write, close_on_finish;
    function(mixed|void:mixed|void) _write_cb;
    function(void | mixed, void | int : void | mixed) _error_cb;
    array(string) out_buffer = allocate(64);
    int out_buffer_stop = -1;
    int out_buffer_length = 0;

    mixed set_write_callback(mixed ... x) {
	return 0;
    }

    mixed query_write_callback(mixed ... x) {
	return lambda() { error("Really? You bought that?\n"); };
    }

    void set_error_callback(function(void | mixed, void | int : void | mixed) c) {
	_error_cb = c;
    }

	void set_nonblocking_keep_callbacks(mixed ... x) {
		error("keep off!\n");
	}
	void set_nonblocking(mixed ... x) {
		error("keep off!\n");
	}

    function(void | mixed, void | int : void | mixed) query_error_callback() {
	return _error_cb;
    }

    int assign(this_program|Stdio.File|Stdio.Fd f) {
	int res;

	res = ::assign(f);

	if (Program.inherits(object_program(f), this_program)) {
	    _error_cb = [function(void | mixed, void | int : void | mixed)]f->_error_cb;
	}

	::set_nonblocking_keep_callbacks();

	return res;
    }

    this_program dup() {
	this_program n = this_program();
	n->assign(this);

	return n;
    }

    void close_when_finished() {
	close_on_finish = 1;
    }

    int write(array(string)|string what, mixed ... fmt) {
	int length;

	if (stringp(what)) {
	    if (sizeof(fmt)) {
		    what = sprintf(what, @fmt);
	    }

	    length = sizeof(what);

	    if (sizeof(out_buffer) == out_buffer_stop + 1)	{
		    out_buffer += allocate(64);
	    } 

	    out_buffer[++out_buffer_stop] = what;
	} else if (sizeof(fmt)) {
	    error("That's not how this works.\n");
	} else { 
	    if (sizeof(out_buffer) - 1 - out_buffer_stop >= sizeof(what)) {
		foreach (what;int i;string t) out_buffer[out_buffer_stop+i+1] = t;
	    } else 
		out_buffer = out_buffer[0..out_buffer_stop] + what + allocate(64);
	    }
	    out_buffer_stop += sizeof(what);
	    length = `+(@map(what, sizeof));
	}

	out_buffer_length += length;
#endif


	if (!will_write) {
		will_write = 1;
		::set_write_callback(do_write);
	}

	return length; // that's kind of a lie, as for Stdio.File it means
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
	int written;

	written = ::write(out_buffer[0..out_buffer_stop]);

	if (written < 0) {

	    if (_error_cb) {
		_error_cb(query_id(), written);
	    } else {
	        close();
	    }
		return;
	} 

#if constant(Meteor)
	Meteor.measure(written);
#endif

	if (written < out_buffer_length) {
		out_buffer_length -= written;

	    	foreach (out_buffer;int i;string t) {
			if (sizeof(t) > written) {
			    out_buffer[i] = t[written..];
			    out_buffer = out_buffer[i..];
			    out_buffer_stop -= i;
			    break;
			} else if (sizeof(t) == written) {
			    out_buffer = out_buffer[i+1..];
			    out_buffer_stop -= i+1;
			    break;
			} else {
			    written -= sizeof(t);
			}
		}
	} else if (close_on_finish) {
	    close();
	    out_buffer = ({});
	    out_buffer_stop = -1;
	    out_buffer_length = 0;
	    close_on_finish = 0;
	    will_write = 0;
	    ::set_write_callback(0);
	    return;
	} else {
	    will_write = 0;
	    ::set_write_callback(0);
	    out_buffer_stop = -1;
	    out_buffer_length = 0;
	    return;
	}

    }
