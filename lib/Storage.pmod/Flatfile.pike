inherit Volatile;

string filename;

string readfile() {
    Stdio.File in;
    string data;

    catch {
	in = Stdio.File(filename, "r");
	data = in->read();
	in->close();
    };
    
    array a = Serialization.parse_atoms(data);

    if (sizeof(a) != 1) { // we assume that there is one root
	werror("Bad data in storage.\n");
    }

    storage = a[0];
}

int writefile() {
    Stdio.File out;
    mixed err;

    err = catch {
	out = Stdio.File(filename, "cwt");
	out->write(storage->render());
	out->close();
    };

    if (err) werror("writing to flatfile %s failed: %O\n", filename, err);
    return !err;
}

void create(string file, mixed|void cb) {
    filename = Stdio.simplify_path(file);

    _destructstorecb = cb;

    if (filename[0] != '/') filename = "./" + filename;

    data = decode(readfile());

    if (!mappingp(data)) data = ([ ]);
}

void apply(object signature, Serialization.Atom change, function callback, mixed ... args) {
    
    void save_on_change(int err, object misc) {
	if (err == Serialization.Types.OK) {
	    if (misc->changed) {
		writefile();
	    }
	}

	callback(err, misc, @args);
    }
}

