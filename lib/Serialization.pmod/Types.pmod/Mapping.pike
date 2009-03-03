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

mapping apply(Serialization.Atom a, Serialization.Atom state, void|function set) {
    if (!a->action) {
	error("cannot apply data atom to a state.\n");
    }

    mapping t;
    int create;

    switch (a->action) {
    case "_query":
	return state;
    case "_add":
	// array(Atom)
	// ØPTIMIZE LATER!
	state->pdata += a->pdata;
	break;
    case "_sub":
	state->typed_data[this] -= decode(a);
	break;
    case "_index_create":
	create = 1;
    case "_index":
	if (!a->pdata) error("bad index: %O\n", a->pdata);
	if (sizeof(a->pdata) != 2) error("bad index.\n");
	object ktype = get_ktype(a->pdata[0]);
	mixed key = ktype->decode(a->pdata[0]);
	object vtype = get_vtype(key, ktype, a->pdata[1]);

	// optimize! this is linear search!
	for (int i =0; i < sizeof(state->pdata); i+=2) {
	    if (state->pdata[i] == a->pdata[0]) {
		array t = state->pdata;
		t[i+1] = vtype->apply(a->pdata[1], t[i+1]);
		state->pdata = t;
		return t[i+1];
	    }
	}

	error("Index %O not found.\n", a->pdata[0]);
    default:
	error("unsupported action.\n");
    }
    return state;
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

