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
	    "_members" : m = List(UTF8String()),
		  ]));

    }
    int test2() {
	mapping t = ([ 
	     "_members" : ({ "sdkfh", "mich", "sldkjf" }),
	     "_amount_wurst" : 2,
	     "_nick" : "kalle",
	     "_some" : ({ "uhu" }),
	]);

	Atom a = p->encode(t);
	Atom b = m->encode(({ "wuuhu", "duuhu" }));
	b->action = "_add";
	b = p->encode(([ "_members" : b ]));
	b->action = "_index";
	t = p->apply(b, t);

	werror("state: %O\n", t);

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
    werror("test2: %O\n", o->test2());
}
