// test examples from json.org

inherit Serialization.Signature;
inherit Serialization.BasicTypes;
inherit Serialization.PsycTypes;

void create() {
	::create(Serialization.TypeCache());
}

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
	object poly = Serialization.Types.Polymorphic();
	poly->register_type("string", "_string", UTF8String());
	poly->register_type("string", "_method", Method());
	poly->register_type("array", "_list", List(poly));
	poly->register_type("mapping", "_mapping", Mapping(Method(), poly));

	object p = Mapping(Method(), poly);
	int td = -(gethrvtime(1) - gethrvtime(1));

	int tt;
	int t1 = gethrvtime(1);
	do {
		string s = Public.Parser.JSON2.render(m);
		tt = gethrvtime(1);
		mapping n = Public.Parser.JSON2.parse(s);
	} while (0);
	int t2 = gethrvtime(1);
	werror("json2: r:%2.3f p:%2.3f micros\n", (tt-t1)*1E-3, (t2-tt)*1E-3);

	t1 = gethrvtime(1);
	do {
		string s = p->render(m, MMP.Utils.StringBuilder())->get();
		tt = gethrvtime(1);
		object atom = Serialization.parse_atoms(s)[0];
		mapping n = p->decode(atom);
	} while (0);
	t2 = gethrvtime(1);
	werror("atom: r:%2.3f p:%2.3f micros\n", (tt-t1)*1E-3, (t2-tt)*1E-3);

	t1 = gethrvtime(1);
	do {
		object atom = p->encode(m);
		mapping n = p->decode(atom);
	} while (0);
	t2 = gethrvtime(1);
	werror("atom cached: %2.3f micros\n", (t2-t1)*1E-3);

	return 0;
}
