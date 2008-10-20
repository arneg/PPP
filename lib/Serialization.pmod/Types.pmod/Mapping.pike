inherit .Base;

Serialization.Atom add(mapping v, void|function ret) {
    Serialization.Atom a = encode(v);
    a->action = "_add";

    if (ret) {
	return ret(a);
    } else {
	return a;
    }
}

Serialization.Atom sub(mapping v, void|function ret) {
    Serialization.Atom a = encode(v);
    a->action = "_sub";

    if (ret) {
	return ret(a);
    } else {
	return a;
    }
}

object index(mixed key, void|function ret) {
    write("index(%O)\n", key);
    object ktype = get_ktype(key);
    if (!ktype->can_encode(key)) {
	error("bad index\n");
    }

    object vtype = get_vtype(key, ktype, UNDEFINED);

    if (vtype) {
	Serialization.Atom a = Serialization.Atom("_mapping", 0);
	a->action = "_index";
	Serialization.Atom f(Serialization.Atom v) {
	    write("return(%O)\n", key);
	    a->pdata = ({ ktype->encode(key), v });
	    if (ret) {
		return ret(a);
	    } else {
		return a;
	    }
	};

	return Serialization.CurryObject(vtype, f);
    } else {
	error("unknown index.\n");
    }

}

mapping apply(Serialization.Atom a, mapping state, void|function set) {
    if (!a->action) {
	error("cannot apply data atom to a state.\n");
    }

    mapping t;
    int create;

    switch (a->action) {
    case "_query":
	return state;
    case "_add":
	t = decode(a);
	if (!state) set(t);
	else set(state + t);
	break;
    case "_sub":
	t = decode(a);
	if (!state) break; // silently ignore non-existing
	set(state - t);
	break;
    case "_index_create":
	create = 1;
    case "_index":
	if (!a->pdata && !low_decode(a)) error("odd number of atoms dont make a mapping. %O\n", a->pdata);
	if (sizeof(a->pdata) != 2) error("bad index.\n");

	object ktype = get_ktype(a->pdata[0]);
	mixed key = ktype->decode(a->pdata[0]);
	
	if (!has_index(state, key) && !create) {
	    error("indexing non-existing entry.\n");
	}

	object vtype = get_vtype(key, ktype, a->pdata[1]);

	void s(mixed val) {
	    state[key] = val;
	};
	
	// TODO: maybe issue a warning on else
	if (!vtype) error("unsupported action in index.\n");

	return vtype->apply(a->pdata[1], state[key], s);
    default:
	error("unsupported action.\n");
    }
}


int(0..1) low_decode(Serialization.Atom a) {
    if (!a->data) a->low_render();

    object parser = Serialization.AtomParser();

    parser->feed(a->data);
    array(Serialization.Atom) list = parser->parse_all();

    if (sizeof(list) & 1) return 0;

    // we keep the array.. more convenient
    a->pdata = list;

    return 1;
}

mapping decode(Serialization.Atom a);
object get_ktype(mixed key);
object get_vtype(mixed key, object ktype, mixed value);
int(0..1) can_encode(mixed m);

string render(mapping m) {
    String.Buffer buf = String.Buffer();
    
    foreach (m; string key; mixed value) {

	object ktype = get_ktype(key);

	if (!ktype) error("something totally unexpected happened during render. seems like %O has been changed since encode()\n", m);

	object vtype = get_vtype(key, ktype, value);

	if (!vtype) error("something totally unexpected happened during render. seems like %O has been changed since encode()\n", m);

	ktype->encode(key)->render(buf);
	vtype->encode(value)->render(buf);
    }

    return (string)buf;
}

Serialization.Atom encode(Serialization.Atom|mixed m) {
    if (low_can_decode(m)) return m;
    if (!can_encode(m)) error("cannot encode %O\n");

    Serialization.Atom atom = Serialization.Atom("_mapping", 0);
    atom->typed_data[this] = m;
    atom->signature = this;

    return atom;
}

int(0..1) low_can_encode(mixed a) {
    return mappingp(a);
}

