inherit .Base;
object type;
object itype = Serialization.Types.Int();

void create(object type) {
    ::create("_list");
    
    this_program::type = type;
}

Serialization.Atom add(array v, void|function ret) {
    Serialization.Atom a = encode(v);
    a->action = "_add";

    if (ret) {
	return ret(a);
    } else {
	return a;
    }
}

Serialization.Atom sub(array v, void|function ret) {
    Serialization.Atom a = encode(v);
    a->action = "_sub";

    if (ret) {
	return ret(a);
    } else {
	return a;
    }
}

object index(int n, void|function ret) {
    write("index(%O)\n", n);
    if (!itype->can_encode(n)) {
	error("bad index\n");
    }

    Serialization.Atom a = Serialization.Atom("_list", 0);
    Serialization.Atom b = itype->encode(n);
    a->action = "_index";
    a->signature = this;
    Serialization.Atom f(Serialization.Atom v) {
	write("return(%O) %O\n", n, b);
	a->pdata = ({ b, v });
	if (ret) {
	    return ret(a);
	} else {
	    return a;
	}
    };

    return Serialization.CurryObject(type, f);
}

Serialization.Atom apply(Serialization.Atom atom, Serialization.Atom state, void|object misc) {
    if (!atom->action) {
	error("cannot apply data atom to a state.\n");
    }

    if (!misc) misc = Serialization.ApplyInfo();

    switch (atom->action) {
    case "_query":
	break;
    case "_add":
	to_medium(state);
	to_medium(atom);
	state->set_pdata(state->pdata + atom->pdata);
	misc->changed = 1;
	break;
    case "_sub":
	// optimize
	to_medium(state);
	to_medium(atom);
	state->set_pdata(state->pdata - atom->pdata);
	misc->changed = 1;
	break;
    case "_index":
	to_medium(state);
	to_medium(atom);
	array index = atom->pdata;
	array astate = state->pdata;

	// this is baad!
	int key = itype->decode(index[0]);

	if (key >= sizeof(astate)) {
	    error("indexing non-existing entry.\n");
	}

	if (sizeof(index) == 1) { // index
	    return astate[key];    
	} else if (sizeof(atom->pdata) == 2) {
	    misc->depth++;
	    mixed ret = type->apply(atom->pdata[1], astate[key], misc);
	    misc->depth--;
	    if (misc->changed) state->set_pdata(astate);
	    werror("list returning %O\n", ret->data||ret->pdata);
	    return ret;
	} 
    default:
	error("unsupported action.\n");
    }

    return state;
}

array decode(Serialization.Atom a) {
    to_done(a);
    return a->typed_data[this];
}

// dont use this
// TODO: may not throw due to can_decode
void raw_to_medium(Serialization.Atom atom) {
    if (arrayp(atom->pdata)) return;
    if (!stringp(atom->data)) error("No raw state.\n");
    atom->pdata = Serialization.parse_atoms(atom->data);
}

void medium_to_raw(Serialization.Atom atom) {
    if (stringp(atom->data)) return;
    if (!arrayp(atom->pdata)) error("No raw state.\n");
    
    String.Buffer buf = String.Buffer();

    if (atom->action == "_index") {
	itype->to_raw(atom->pdata[0]);
	buf = atom->pdata[0]->render(buf);
	type->to_raw(atom->pdata[1]);
	buf = atom->pdata[1]->render(buf);
    } else {
	foreach (atom->pdata;;Serialization.Atom a) {
	    type->to_raw(a);
	    buf = a->render(buf);	
	}
    }

    atom->data = (string)buf;
}

void medium_to_done(Serialization.Atom atom) {
    if (has_index(atom->typed_data, this)) return;
    if (!arrayp(atom->pdata)) error("No medium state.\n");
    atom->typed_data[this] = map(atom->pdata, type->decode);
}

void done_to_medium(Serialization.Atom atom) {
    if (arrayp(atom->pdata)) return;
    if (!has_index(atom->typed_data, this)) error("No done state.\n");
    atom->pdata = map(atom->typed_data[this], type->encode);
}

void to_done(Serialization.Atom atom) {
    if (has_index(atom->typed_data, this)) return;

    raw_to_medium(atom);
    medium_to_done(atom);
}

void to_raw(Serialization.Atom atom) {
    if (atom->data) return;

    done_to_medium(atom);
    medium_to_raw(atom);
}

void to_medium(Serialization.Atom atom) {
    if (has_index(atom->typed_data, this)) {
	done_to_medium(atom);
    } else if (this != atom->signature && atom->signature && has_index(atom->signature, "to_medium")) {
	atom->signature->to_medium(atom);
    } else {
	raw_to_medium(atom);
    }
}

Serialization.Atom encode(Serialization.Atom|array a) {
    if (low_can_decode(a)) return a;
    // we want late rendering...!!!
    foreach (a;; mixed t) {
	if (!type->can_encode(t)) {
	    error("%O cannot encode %O.", type, t);
	}
    }

    Serialization.Atom atom = Serialization.Atom("_list", 0);
    atom->typed_data[this] = a;
    atom->signature = this;

    return atom;
}

int(0..1) can_decode(Serialization.Atom a) {
    if (a->typed_data[this]) return 1;
    if (!low_can_decode(a)) return 0;

    to_medium(a);

    foreach (a->pdata;;Serialization.Atom i) {
	if (!type->can_decode(i)) {
	    return 0;
	}
    }

    return 1;
}

int (0..1) low_can_encode(mixed a) {
    return arrayp(a);
}

int(0..1) can_encode(mixed a) {
    if (low_can_decode(a)) return 1;
    if (!arrayp(a)) {
	return 0;
    }

    foreach (a;;mixed i) {
	if (!type->can_encode(i)) {
	    return 0;
	}
    }

    return 1;
}

string _sprintf(int c) {
    if (c == 'O') {
	return sprintf("List(%O)", type);
    }

    return 0;
}
