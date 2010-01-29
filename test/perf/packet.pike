// test examples from json.org

inherit Serialization.Signature;
inherit Serialization.BasicTypes;
inherit Serialization.PsycTypes;

void create() {
	::create(Serialization.TypeCache());
}

class S { 
	MMP.Uniform get_uniform(string u) {
		return MMP.Uniform(u);
	}
}

float average(int(1..) n, function f, mixed ... args) {
	int t1 = gethrvtime(1);

	int m = n;
	while (m--) {
		f(@args);
	}
	
	return (gethrvtime(1) - t1)/(float)n;
}

object server = S();

int main() {

	mapping m = Public.Parser.JSON2.parse("{\
		\"glossary\": {\
			\"title\": \"example glossary\",\
		\"GlossDiv\": {\
				\"title\": \"S\",\
			\"GlossList\": {\
					\"GlossEntry\": {\
						\"ID\": \"SGML\",\
				\"SortAs\": \"SGML\",\
				\"GlossTerm\": \"Standard Generalized Markup Language\",\
				\"Acronym\": \"SGML\",\
				\"Abbrev\": \"ISO 8879:1986\",\
				\"GlossDef\": {\
							\"para\": \"A meta-markup language, used to create markup languages such as DocBook.\",\
				\"GlossSeeAlso\": [\"GML\", \"XML\"]\
						},\
				\"GlossSee\": \"markup\"\
					}\
				}\
			}\
		}\
	}\ ");

	MMP.Packet packet = MMP.Packet(m, ([ "_source" : MMP.Uniform("psyc://example.org/~user1"), "_target" : MMP.Uniform("psyc://example.org/~user2") ]));
	
	object poly = Serialization.Types.PBuilder();
	poly->register_type("string", "_string");
	poly->register_type("string", "_method");
	poly->register_type("array", "_list");
	poly->register_type("mapping", "_mapping");
	poly = poly->optimize();
	poly->t0 = UTF8String();
	poly->t1 = Method();
	poly->t2 = List(poly);
	poly->t3 = Mapping(Method(), poly);
	object ptype = Packet(Mapping(Method(), poly));

	string s;
	void f1() {
		s = ptype->render(packet);
	};
	void f2() {
		object atom = Serialization.parse_atoms(s)[0];
		MMP.Packet n = ptype->decode(atom);
	};
	werror("atom: r: %2.3f p: %2.3f micros\n", average(1000, f1)*1E-3, average(1000, f2)*1E-3);

	return 0;
}
