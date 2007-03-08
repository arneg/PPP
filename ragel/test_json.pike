string s1 = " [[[[{ \"sdfsdfsdf\" : [ 32, 435, 54.456 ] }]]]] ";
string s2 = "{ \"glossary\": { \"title\\uffff\" \"example glossary\\u3043\", \"GlossDiv\": { \"title\": \"S\", \"GlossList\": { \"GlossEntry\": { \"ID\": \"SGML\", \"SortAs\": \"SGML\", \"GlossTerm\": \"Standard Generalized Markup Language\", \"Acronym\": \"SGML\", \"Abbrev\": \"ISO 8879:1986\", \"GlossDef\": { \"para\": \"A meta-markup language, used to create markup languages such as DocBook.\", \"GlossSeeAlso\": [\"GML\", \"XML\"] }, \"GlossSee\": \"markup\" } } } } } ";

int main() {

    write("%s\n\n", s2);

    write("%O\n", Public.Parser.JSON2.parse(s2));

    write("%O\n", JSON.parse(s2, 0, 0, ([])));
}
