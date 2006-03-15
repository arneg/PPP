// vim:syntax=lpc

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
	    return sprintf("FlatFile(%O)", data);
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
