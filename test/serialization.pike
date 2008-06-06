import Serialization;

class Test {
    inherit Serialization.Signature;
    inherit Serialization.BasicTypes;

    object m;

    void init() {

	m = Mapping(String(), Or(Int(), List(Or(String(), List(Int())))));

    }

    void test() {
	mapping t = ([ 
	     "hehe" : ({ "sdkfh", ({ 1, 4, 5, 3, 4 }), "sldkjf" }),
	     "wuhuhu" : 2,
	]);
	Atom a = m->encode(t);

	werror("%O\n", a->data);

	mapping t2 = m->decode(a);

	if (equal(t, t2)) {
	    werror("hooray!!!\n");
	}
    }
}


int main() {
    object cache = TypeCache();

    object o = Test(cache);

    o->init();
    o->test();
}
