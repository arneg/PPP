import Serialization;

inherit Test.Simple;

class Test1 {
    inherit Serialization.Signature;
    inherit Serialization.BasicTypes;
    inherit Serialization.PsycTypes;

    object m, p, pp;
    mapping t = ([ 
	 "_members" : ({ ([ "sdkfh" : 3 ]), ([ "mich" : 45 ]), ([ "sldkjf" : 123 ]) }),
	 "_amount_wurst" : 2,
	 "_nick" : "kalle",
	 "_some" : ({ "uhu" }),
    ]);


    void init() {
	p = Vars(([]),([
	    "_nick" : UTF8String(),
	    "_amount" : Int(),
	    "_members" : List(Mapping(UTF8String(), Int())),
		  ]));
	pp = Types.Polymorphic();
	pp->register_type("string", "_method", Method());
	pp->register_type("string", "_string", UTF8String());
	pp->register_type("int", "_integer", Int());
	pp->register_type("mapping", "_mapping", Mapping(pp,pp));
	pp->register_type("array", "_list", List(pp));
    }

    int test_unlocked() {
	return 1;
	/*
	Atom a = p->encode(t);
	mapping t2 = p->decode(a);

	if (equal(t, t2)) {
	    return 1;
	}
	*/
	Serialization.Atom state = p->encode(t);
	Serialization.Atom b = p->index("_members")->index(1)->add(([ "wuuu" : 23234234 ]));
	Serialization.Atom c = p->index("_members")->index(1)->query();
	//werror("state: %O\n", t);
	array(object) path = c->path();
	//werror("QUERY: %O\n", b->render());
	object misc = Serialization.Types.ApplyInfo();

	int i = pp->apply(c, state, misc);
	if (i && i == Serialization.Types.UNSUPPORTED) {
	    werror("Is unsupported.\n");
	    werror("Unsupported type was %O.\n", path[misc->faildepth]);
	    werror("also locked: %O\n", misc->lock);
	} else if (i && i == Serialization.Types.LOCKED) {
	    werror("Is locked.\n");
	} else {
	    werror("ok. %O\n", misc);
	}
	//ok(equal(t["_members"][1], misc->state()->signature->decode(misc->state())));
	werror("QUERY RESULT: %O\n", misc->state());

	object misc2 = Serialization.Types.ApplyInfo();
	int a = pp->apply(b, state, misc2);
	werror("QUERY RESULT: %O\n", misc->state());
    }

    int test_locking() {
	Serialization.Atom state = p->encode(t);
	Serialization.Atom b = p->index("_members")->index(2)->query_lock();
	Serialization.Atom d = p->index("_members")->index(0)->query_lock();
	Serialization.Atom add = p->index("_members")->index(2)->add(([ "uuuh" : 234324 ]));
	Serialization.Atom unlock = p->index("_members")->index(2)->unlock();
	Serialization.Atom e = p->index("_members")->index(0)->unlock();
	
	foreach (({ b, add, d, unlock, add, e });;Serialization.Atom change) {
	    array(object) path = change->path();
	    object misc = Serialization.Types.ApplyInfo();
	    int i = pp->apply(change, state, misc);
		    
	    if (i && i == Serialization.Types.UNSUPPORTED) {
		werror("Is unsupported.\n");
		werror("Unsupported type was %O.\n", path[misc->faildepth]);
		werror("also locked: %O\n", misc->lock);
	    } else if (i && i == Serialization.Types.LOCKED) {
		werror("Is locked.\n");
	    } else {
		werror("ok.\n", misc);
	    }
	}

	werror("end: %O\n", pp->decode(state));

    }
}


int main() {
    object cache = TypeCache();

    object o = Test1(cache);

    test_object(o);
}
