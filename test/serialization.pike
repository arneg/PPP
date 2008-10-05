import Serialization;

class Test {
    inherit Serialization.Signature;
    inherit Serialization.BasicTypes;
    inherit Serialization.PsycTypes;

    object m, p, pp;

    void init() {

	m = Mapping(
		UTF8String(), Or(Int(), 
			     List( Or(UTF8String(), List(Int())) )
				 )
		    );

	p = Vars(([
	    "_nick" : UTF8String(),
	    "_amount" : Int(),
	    "_members" : List(UTF8String()),
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

    int test3() {
	object p = PSYC.Packet("_message_public", ([ "_nick" : "example" ]), "hello you sucker!");
	pp = PsycPacket("_message", UTF8String());

	Atom t = pp->encode(p);
	werror("packet: %O\n", t->data);

	return 0;
    }
}


int main() {
    object cache = TypeCache();

    object o = Test(cache);

    o->init();
    werror("cache: %O\n", cache);
    werror("test1: %O\n", o->test1());
    werror("test2: %O\n", o->test2());
    werror("test2: %O\n", o->test3());
}
