// this piece of code has been tested on hackers excessively!

inherit Stdio.Port;

program|object|function _fileclass;

void create(int|string|void port,
	    function|void accept_callback,
	    string|void ip,
	    program|object|function|void fileclass) {
    _fileclass = fileclass;
    ::create(port, accept_callback, ip);
}

object accept() {
    Stdio.File file;
    object cool_file;

    if (_fileclass && (cool_file = _fileclass())) {
	file = ::accept();
	cool_file->assign(file);
    } else {
	cool_file = ::accept();
    }

    return cool_file;
}
