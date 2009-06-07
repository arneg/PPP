// vim:syntax=c

#include "lock.h"
#include "type.h"

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
	    a->child = v;

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

int apply(Serialization.Atom atom, Serialization.Atom state, void|object misc) {
    if (!atom->action) {
	error("cannot apply data atom to a state.\n");
    }

    if (!misc) misc = .ApplyInfo();

    misc->path += ({ state });


    if (has_suffix(atom->action, "_unlock")) {
	if (!state->_locked) error("Trying to unlock unlocked state.\n");
	UNLOCK_WALK();

	if (atom->action == "_unlock") {
	    return .OK;
	}
    }

    if (atom->action != "_query") {
	to_medium(state);
	to_medium(atom);
    }

    if (atom->action == "_query") {
	return .OK;
    } else if (Serialization.is_subtype_of(atom->action, "_index")) {
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
	    if (atom->_locked) {
		// this will hit the _one_ locked, so we can error
		if (misc->locked_above) error("Found nested lock!\n");
		misc->locked_above = 1;
		misc->lock = atom;
	    }
	    int ret = vtype->apply(index[1], m[key], misc);

	    misc->depth--;

	    return ret;
	}
    }

    // a pure query may always succeed. we dont care about inconsistency then
    // for the rest we have to shout
    if (misc->locked_above) {
	return .LOCKED;
    }

    CHECK_LOCK();

    switch (atom->action) {
    case "_query_lock":
	CHECK_LOCK();
	LOCK_WALK();
	werror("LOCKING %O\n", state);
	return .OK;
    case "_add_lock":
	CHECK_LOCKS();
	LOCK_WALK();
    case "_add":
	// check if we would overwrite any locked keys
	if (sizeof(state->children)) foreach (atom->pdata;Serialization.Atom key;) {
	    if (has_index(state->pdata, key)) {
		CHECK_CHILD(state->pdata[key]);
	    }
	}
	// ØPTIMIZE LATER:
	// we can perform the addiction/substraction
	// on all typed representations aswell and thus
	// saving some reparsings. this may not be worth
	// the effort in all cases... hard to tell
	state->set_pdata(state->pdata + atom->pdata);
	misc->changed = 1;
	CLEAR_WALK();
	return .OK;
    case "_sub_lock":
	CHECK_LOCKS();
	LOCK_WALK();
    case "_sub":
	if (sizeof(state->children)) foreach (atom->pdata;Serialization.Atom key;) {
	    if (has_index(state->pdata, key)) {
		CHECK_CHILD(state->pdata[key]);
	    }
	}
	state->set_pdata(state->pdata - atom->pdata);
	misc->changed = 1;
	CLEAR_WALK();
	return .OK;
    default:
	return .UNSUPPORTED;
    }
}

object get_ktype(mixed key);
object get_vtype(mixed key, object ktype, mixed value);
int(0..1) can_encode(mixed m);

void done_to_medium(Serialization.Atom atom) {
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

    mapping m = ([]);

    if (sizeof(list) & 1) return 0;

    // we keep the array.. more convenient
    for (int i=0;i<sizeof(list);i+=2) {
		m[list[i]] = list[i+1];
    }

    atom->pdata = m;
}

void medium_to_raw(Serialization.Atom atom) {
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

int(0..1) low_can_encode(mixed a) {
    return mappingp(a);
}
