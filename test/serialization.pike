import Serialization;

class Test {
    inherit Serialization.Signature;
    inherit Serialization.BasicTypes;
    inherit Serialization.PsycTypes;

    object m, p, pp;

    void init() {
	p = Vars(([]),([
	    "_nick" : UTF8String(),
	    "_amount" : Int(),
	    "_members" : List(Mapping(UTF8String(), Int())),
		  ]));

    }
    int test2() {
	mapping t = ([ 
	     "_members" : ({ ([ "sdkfh" : 3 ]), ([ "mich" : 45 ]), ([ "sldkjf" : 123 ]) }),
	     "_amount_wurst" : 2,
	     "_nick" : "kalle",
	     "_some" : ({ "uhu" }),
	]);

	/*
	Atom a = p->encode(t);
	mapping t2 = p->decode(a);

	if (equal(t, t2)) {
	    return 1;
	}
	*/
	Atom b = p->index("_members")->index(1)->add(([ "wuuu" : 23234234 ]));
	werror("state: %O\n", t);
	werror("%O\n", b);
	p->apply(b, t);
	werror("state: %O\n", t);
    }
}


int main() {
    object cache = TypeCache();

    object o = Test(cache);

    o->init();
    werror("cache: %O\n", cache);
    werror("test2: %O\n", o->test2());
}
