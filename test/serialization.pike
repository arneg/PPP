import Serialization;

class Test {
    inherit Serialization.Signature;
    inherit Serialization.BasicTypes;
    inherit Serialization.PsycTypes;

    object m, p;

    void init() {

	m = Mapping(String(), Or(Int(), List(Or(String(), List(Int())))));

	p = Vars(([
	    "_nick" : String(),
	    "_amount" : Int(),
	    "_members" : List(String()),
		  ]));

    }

    int test1() {
	mapping t = ([ 
	     "hehe" : ({ "sdkfh", ({ 1, 4, 5, 3, 4 }), "sldkjf" }),
	     "wuhuhu" : 2,
	]);

	Atom a = m->encode(t);

	werror("%O\n", a->data);

	mapping t2 = m->decode(a);

	if (equal(t, t2)) {
	    return 1;
	}
    }

    int test2() {
	mapping t = ([ 
	     "_members" : ({ "sdkfh", "mich", "sldkjf" }),
	     "_amount_wurst" : 2,
	     "_nick" : "kalle",
	     "_some" : ({ "uhu" }),
	]);

	Atom a = p->encode(t);

	werror("%O\n", a->data);

	mapping t2 = p->decode(a);

	if (equal(t, t2)) {
	    return 1;
	}
    }
}


int main() {
    object cache = TypeCache();

    object o = Test(cache);

    o->init();
    werror("cache: %O\n", cache);
    werror("test1: %O\n", o->test1());
    werror("test2: %O\n", o->test2());
}
