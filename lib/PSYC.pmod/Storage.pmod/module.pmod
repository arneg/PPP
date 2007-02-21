// vim:syntax=lpc
#include <debug.h>

constant OK = 0;
constant ERROR = 1;
constant TEMP_ERROR = 2;
constant PERMANENT_ERROR = 3;

void aggregate(object storage, multiset locked_vars, multiset vars, function callback, function fail, mixed ... args) {
    P3(("Storage", "aggregate(%O, %O, %O, %O, %O, %O)\n", storage, locked_vars, vars, callback, fail, args))

    void fetched(string key, mixed value, multiset locked_vars, multiset vars, mapping(string:mixed) new, function callback, function fail, mixed args) {

	PT(("Storage", "fetched(%O,%O,%O,%O,%O,%O,%O)\n", key, value, locked_vars, vars, new, callback, args))
		
	if (has_index(new, key)) {
	    THROW(sprintf("key %O received twice. duh.\n", key));
	}

	if (!(locked_vars && has_index(locked_vars, key) || vars && has_index(vars, key))) {
	    THROW(sprintf("some bozo sent us key %O, but we didn't request that. punish him!\n", key));
	}

	new[key] = value;

	if (sizeof(new) == (locked_vars && sizeof(locked_vars)) + (vars && sizeof(vars))) {
	    call_out(callback, 0, new, @args);
	}
    };

    mapping(string:mixed) new = ([]);
    int isclown = 1;

    if (locked_vars) foreach (locked_vars; string key;) {
	isclown = 0;
	storage->get_lock(key, fetched, locked_vars, vars, new, callback, fail, args);
    }

    if (vars) foreach (vars; string key;) {
	isclown = 0;
	storage->get(key, fetched, locked_vars, vars, new, callback, fail, args);
    }

    if (isclown) {
	call_out(callback, 0, new, @args);
    }
}

class Storage {
    mixed _destructstorecb;

    void destroy() {
	if (_destructstorecb) {
	    _destructstorecb();
	}
    }
}

class MappingBased {
    inherit Storage;

    mapping data;

    array _indices() {
	return indices(data);
    }

    mixed _m_delete(mixed index) {
	return m_delete(data, index);
    }

    mixed _search(mixed needle, mixed|void start) {
	return search(data, needle, start);
    }

    int _sizeof() {
	return sizeof(data);
    }

    string _sprintf(int format) {
	if (format == 'O') {
	    return sprintf("%O(%O)", this_program, data);
	}
    }

    array _values() {
	return values(data);
    }

    mixed `[](mixed index) {
	return data[index];
    }
    
    mixed `[]=(mixed index, mixed value) {
	return data[index] = value;
    }

    /*
    function (mixed:mixed) `-> = `[];

    function (mixed,mixed:mixed) `->= = `[]=;
    */

    mixed cast(string type) {
	if (type == "mapping") {
	    return copy_value(data);
	}
    }

    void clear() {
	data = ([ ]);
    }
}

class FlatFile {
    inherit MappingBased;

    string filename;

    string encode(mixed stuff) {
	return encode_value(stuff);
    }

    mixed decode(string stuff) {
	catch {
	    return decode_value(stuff);
	};
    }

    string readfile() {
	Stdio.File in;
	string ret;

	catch {
	    in = Stdio.File(filename, "r");
	    ret = in->read();
	    in->close();
	};

	return ret;
    }

    int writefile(string stuff) {
	Stdio.File out;
	mixed err;

	err = catch {
	    out = Stdio.File(filename, "cwt");
	    out->write(stuff);
	    out->close();
	};

	return !err;
    }

    void create(string file, mixed|void cb) {
	filename = Stdio.simplify_path(file);

	_destructstorecb = cb;

	if (filename[0] != '/') filename = "./" + filename;

	data = decode(readfile());

	if (!mappingp(data)) data = ([ ]);
    }

    int save() {
	return writefile(encode(data));
    }
}
