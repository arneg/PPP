#include "lock.h"
#include "type.h"

inherit .Base;
object etype;
object itype = Serialization.Types.Int();

void create(object type) {
    ::create("_list");

	if (!objectp(type)) error("Bad type %O\n", type);
    
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
    array|Serialization.Atom f(Serialization.Atom v) {
	write("return(%O) %O\n", n, b);
	a->pdata = ({ b, v });
	a->child = v;

	if (ret) {
	    return ret(a);
	} else {
	    return a;
	}
    };

    return Serialization.CurryObject(etype, f);
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
	    if (atom->_locked) {
		// this will hit the _one_ locked, so we can error
		if (misc->locked_above) error("Found nested lock!\n");
		misc->locked_above = 1;
		misc->lock = atom;
	    }
	    mixed ret = etype->apply(atom->pdata[1], astate[key], misc);
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
	return .OK;
    case "_add_lock":
	CHECK_LOCKS();
	LOCK_WALK();
    case "_add":
	// ØPTIMIZE LATER:
	// we can perform the addition/substraction
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
	if (sizeof(state->children)) foreach (atom->pdata;;Serialization.Atom key) {
	    // check if things we want to remove are locked.
	    if (has_index(state->children, key)) {
		// this doesnt look sane, but its due to the __hash() function
		// of atoms that may make different atoms identical
		misc->lock = state->children[key];
		return .LOCKED;
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

// dont use this
// TODO: may not throw due to can_decode
void raw_to_medium(Serialization.Atom atom) {
    atom->pdata = Serialization.parse_atoms(atom->data);
}

void medium_to_raw(Serialization.Atom atom) {
    if (!arrayp(atom->pdata)) error("broken pdata: %O\n", atom->pdata);
    String.Buffer buf = String.Buffer();

    if (atom->action == "_index") {
		buf = atom->pdata[0]->render(buf);
		buf = atom->pdata[1]->render(buf);
    } else foreach (atom->pdata;;Serialization.Atom a) {
		buf = a->render(buf);	
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
