inherit .Base;
object etype;
object itype = Serialization.Types.Int();

void create(object type) {
    ::create("_list");
    
    this_program::etype = type;
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

    return Serialization.CurryObject(etype, f);
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
	state->set_pdata(to_medium(state) + to_medium(atom));
	misc->changed = 1;
	break;
    case "_sub":
	// optimize
	state->set_pdata(to_medium(state) - to_medium(atom));
	misc->changed = 1;
	break;
    case "_index":
	array index = to_medium(atom);
	array astate = to_medium(state);

	// this is baad!
	int key = itype->decode(index[0]);

	if (key >= sizeof(astate)) {
	    error("indexing non-existing entry.\n");
	}

	if (sizeof(index) == 1) { // index
	    return astate[key];    
	} else if (sizeof(atom->pdata) == 2) {
	    misc->depth++;
	    mixed ret = etype->apply(atom->pdata[1], astate[key], misc);
	    misc->depth--;
	    if (misc->changed) state->set_pdata(astate);
	    werror("list returning %O\n", ret->data||ret->pdata);
	    return ret;
	} 
    default:
	error("unsupported action.\n");
    }

    return state->clone();
}

// dont use this
// TODO: may not throw due to can_decode
void raw_to_medium(Serialization.Atom atom) {
    atom->pdata = Serialization.parse_atoms(atom->data);
}

void medium_to_raw(Serialization.Atom atom) {
    if (!arrayp(atom->pdata)) error("broken pdata: %O\n", atom->pdata);
    String.Buffer buf = String.Buffer();

    if (atom->action == "_index") {
	buf += itype->render(atom->pdata[0]);
	buf += etype->render(atom->pdata[1]);
    } else foreach (atom->pdata;;Serialization.Atom a) {
	buf += etype->render(a);	
    }

    atom->data = (string)buf;
}

void medium_to_done(Serialization.Atom atom) {
    if (!arrayp(atom->pdata)) error("broken pdata: %O\n", atom->pdata);
    atom->typed_data[this] = map(atom->pdata, etype->decode);
}

void done_to_medium(Serialization.Atom atom) {
    if (!arrayp(atom->typed_data[this])) error("broken typed_data: %O\n", atom->typed_data[this]);
    atom->pdata = map(atom->typed_data[this], etype->encode);
}

int (0..1) low_can_encode(mixed a) {
    return arrayp(a);
}

int(0..1) can_encode(mixed a) {
    if (low_can_decode(a)) return 1;
    if (!arrayp(a)) return 0;

    foreach (a;;mixed i) {
	if (!etype->can_encode(i)) {
	    return 0;
	}
    }

    return 1;
}

string _sprintf(int c) {
    if (c == 'O') {
	return sprintf("List(%O)", etype);
    }

    return 0;
}
