string s1 = " [[[[{ \"sdfsdfsdf\" : [ 32, 435, 54.456 ] }]]]] ";
string s2 = "{ \"glossary\": { \"title\": \"example glossary\", \"GlossDiv\": { \"title\": \"S\", \"GlossList\": { \"GlossEntry\": { \"ID\": \"SGML\", \"SortAs\": \"SGML\", \"GlossTerm\": \"Standard Generalized Markup Language\", \"Acronym\": \"SGML\", \"Abbrev\": \"ISO 8879:1986\", \"GlossDef\": { \"para\": \"A meta-markup language, used to create markup languages such as DocBook.\", \"GlossSeeAlso\": [\"GML\", \"XML\"] }, \"GlossSee\": \"markup\" } } } } } ";

int main() {

    write("%s\n\n", s2);
    write("%O\n", Public.Parser.JSON2.parse(s2));
    write("%O\n", JSON.parse(s2, 0, 0, ([])));

    write("c-parser: %f\n", 10000.0*gauge{ for (int i = 0; i <100; i++) Public.Parser.JSON2.parse(s2);});
    write("pike-parser: %f\n", 10000.0*gauge{for (int i = 0; i <100; i++) JSON.parse(s2, 0, 0, ([]));});
}
