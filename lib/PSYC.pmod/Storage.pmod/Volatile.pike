mapping(string:mixed) data;
// we should use the internal caching of atoms and work on them
mapping(string:Serialization.Atom) raw_data;
mapping(string:object) signatures;

void save();

void register_storage(string key, object signature) {
    signatures[key] = signature;
}

void set(string key, mixed value, function callback) {
    object signature = signatures[key];
    if (!signature) {
	werror("Unknown entry %s\n");
	call_out(callback, 0, 0);
    }

    data[key] = value;
    raw_data[key] = signature->encode(value);
    call_out(callback, 0, 1, key);
    save();
}

void remove(string key, function callback) {
    m_delete(data, key);
    m_delete(raw_data, key);

    call_out(callback, 0, 1, key);
    save();
}

void get(string key, function callback) {
    mixed ret;
    if (has_index(data, key)) {
	ret = data[key];
    } else {
	ret = raw_data[key];

	if (!ret) {
	    call_out(callback, 0, 0);
	    return;
	}
	object signature = signatures[key];

	if (!signature) {
	    call_out(callback, 0, 0);
	    werror("Unknown entry %s\n");
	}
	
	data[key] = ret = signature->decode(ret);
    }

    call_out(callback, 0, 1, key, ret);
}

void apply(string key, Serialization.Atom a, function callback) {
    mixed value = data[key];
    object signature = signatures[key];

    if (!signature) error("You need to register a storage var before you use it.\n");
    
    if (objectp(value) && object_program(value) == Serialization.Atom) {
	mixed err = catch {
	    value = signature->decode(value);
	};

	if (err) {
	    // decoding or applying failed.
	    werror("Decoding failed: %O\n", err);

	    call_out(callback, 0, 0);
	    return;
	}
    }

    void s(mixed v) {
	data[key] = v;
	raw_data[key] = signature->encode(v);
	save();
    };

    mixed ret;
    mixed err = catch {
	ret = signature->apply(a, value, s);
    };

    if (err) {
	werror("Applying changes failed: %O\n", err);
	call_out(callback, 0, 0);
	return;
    }

    // we need a plan for remote storage here
    call_out(callback, 0, 1, key, ret);
}

string render() {
    String.Buffer buf = String.Buffer();

    foreach (raw_data;string key;mixed value) {
	Serialization.Atom("string", key)->render(buf);
	value->render(buf);
    }

    return (string)buf;
}

// this could be used by others
void multi_apply(mapping(string:int|Serialization.Atom) stuff, function callback) {
    int num = sizeof(stuff);
    int failed = 0;
    mapping ret = ([]);
    
    void cb(int ok, string key, mixed val) {
	if (ok) {
	    ret[key] = val;
	} else {
	    failed = 1;
	}
	if (!(--num)) {
	    if (failed) {
		MMP.Utils.invoke_later(callback, 0);
	    } else {
		MMP.Utils.invoke_later(callback, ret);
	    }
	}
    };

    foreach (stuff;string key;mixed value) {
	if (objectp(value)) {
	    apply(key, value, cb); 
	} else {
	    get(key, cb);
	}
    }
}
