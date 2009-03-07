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
	a->signature = this;
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

int(0..1) has_pdata(Serialization.Atom atom) {
    return mappingp(atom->pdata) || (atom->action == "_index" && arrayp(atom->pdata)) || (atom->action == "_query");
}

Serialization.Atom apply(Serialization.Atom atom, Serialization.Atom state, void|object misc) {
    if (!atom->action) {
	error("cannot apply data atom to a state.\n");
    }

    if (!misc) misc = Serialization.ApplyInfo();

    int create;

    switch (atom->action) {
    case "_query":
	break;
    case "_add":
	// ØPTIMIZE LATER:
	// we can perform the addiction/substraction
	// on all typed representations aswell and thus
	// saving some reparsings. this may not be worth
	// the effort in all cases... hard to tell
	to_medium(state);
	to_medium(atom);
	state->set_pdata(state->pdata + atom->pdata);
	misc->changed = 1;
	break;
    case "_sub":
	to_medium(state);
	to_medium(atom);
	state->set_pdata(state->pdata - atom->pdata);
	misc->changed = 1;
	break;
    case "_index_create":
	create = 1;
    case "_index":
	to_medium(state);
	to_medium(atom);
	mapping m = state->pdata;
	array index = atom->pdata;
	Serialization.Atom key = index[0];

	if (!has_index(m, key)) {
	    error("Index %O not found.\n", atom->pdata[0]);
	}

	if (sizeof(index) == 1) {
	    return m[key];
	} else if (sizeof(index) == 2) {
	    object vtype = get_vtype(key, get_ktype(key), index[1]);
	    misc->depth++;
	    mixed ret = vtype->apply(index[1], m[key], misc);
	    misc->depth--;

	    if (!state->signature) state->signature = this;
	    if (misc->changed) state->set_pdata(m);

	    return ret;
	}
    default:
	error("unsupported action.\n");
    }

    return state;
}

object get_ktype(mixed key);
object get_vtype(mixed key, object ktype, mixed value);
int(0..1) can_encode(mixed m);

void done_to_medium(Serialization.Atom atom) {
    if (has_pdata(atom)) return;
    if (!has_index(atom->typed_data, this)) error("No done state.\n");

    mapping m = ([]), done = atom->typed_data[this];

    foreach (done; mixed key; mixed value) {
	object ktype = get_ktype(key);
	if (!ktype) error("something totally unexpected happened during render. seems like %O has been changed since encode()\n", done);
	object vtype = get_vtype(key, ktype, value);
	if (!vtype) error("something totally unexpected happened during render. seems like %O has been changed since encode()\n", done);
	Serialization.Atom mkey = ktype->encode(key);
	Serialization.Atom mval = vtype->encode(value);
	m[mkey] = mval;
    }

    atom->pdata = m;
}

void medium_to_done(Serialization.Atom atom) {
    if (!mappingp(atom->pdata)) error("No medium state.\n");
    if (has_index(atom->typed_data, this)) return;

    mapping done = ([]), m = atom->pdata;

    foreach (m;Serialization.Atom mkey;Serialization.Atom mval) {
	object ktype = get_ktype(mkey);
	if (!ktype) error("something totally unexpected happened during render. seems like %O has been changed since encode()\n", done);
	object vtype = get_vtype(mkey, ktype, mval);
	if (!vtype) error("something totally unexpected happened during render. seems like %O has been changed since encode()\n", done);

	mixed key = ktype->decode(mkey);
	mixed val = vtype->decode(mval);
	done[key] = val;
    }

    atom->typed_data[this] = done;
}

void raw_to_medium(Serialization.Atom atom) {
    if (has_pdata(atom)) return;

    if (!stringp(atom->data)) error("No raw state.\n");

    if (atom->action == "_query") {
	if (atom->data == "") {
	    return;
	} else {
	    error("Malformed _query action!");
	}
    }

    array(Serialization.Atom) list = Serialization.parse_atoms(atom->data);

    if (atom->action == "_index") {
	atom->pdata = list;
	return;
    }

    mapping m;

    if (sizeof(list) & 1) return 0;

    // we keep the array.. more convenient
    for (int i=0;i<sizeof(list);i+=2) {
	m[list[i]] = m[list[i+1]];
    }

    atom->pdata = m;
}

void medium_to_raw(Serialization.Atom atom) {
    if (stringp(atom->data)) return;
    if (!has_pdata(atom)) error("No medium state.\n");

    String.Buffer buf = String.Buffer();

    if (atom->action == "_index") {
	foreach (atom->pdata;; Serialization.Atom value) {
	    buf = value->render(buf);
	}
    } else if (atom->action != "_query") {
	foreach (atom->pdata;Serialization.Atom key; Serialization.Atom value) {
	    buf = key->render(buf);
	    buf = value->render(buf);
	}
    }

    atom->data = (string)buf;
}

void to_raw(Serialization.Atom atom) {
    if (stringp(atom->data)) return; 

    done_to_medium(atom);
    medium_to_raw(atom);
}

void to_medium(Serialization.Atom atom) {
    if (has_pdata(atom)) return;

    if (has_index(atom->typed_data, this)) {
	done_to_medium(atom);
    } else if (atom->signature && has_index(atom->signature, "to_medium")) {
	atom->signature->to_medium(atom);
    } else {
	raw_to_medium(atom);
    }
}

void to_done(Serialization.Atom atom) {
    if (has_index(atom->typed_data, this)) return;

    raw_to_medium(atom);
    medium_to_done(atom);
}

mapping decode(Serialization.Atom atom) {
    to_done(atom);
    return atom->typed_data[this];
}

Serialization.Atom encode(Serialization.Atom|mixed m) {
    if (low_can_decode(m)) return m;
    if (!can_encode(m)) error("%O: cannot encode %O\n", this, m);

    Serialization.Atom atom = Serialization.Atom("_mapping", 0);
    atom->set_typed_data(this, m);

    return atom;
}

int(0..1) low_can_encode(mixed a) {
    return mappingp(a);
}

