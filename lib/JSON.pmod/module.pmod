// vim:syntax=lpc
// $Id: module.pmod,v 1.13 2006/12/27 15:56:10 p0rtage Exp $

mixed parse(string json, program|void objectb, program|void arrayb, mapping(int:object) generics) {
#if 0
#if constant(Public)
# if constant(Public.Parser)
#  if constant(Public.Parser.JSON)
    if (!(objectb || arrayb)) {
	return Public.Parser.JSON.parse(json);
    }
#  endif
# endif
#endif
#endif

    return parse_pike(json, objectb, arrayb, generics);
}

mixed parse_pike(string json, program|void objectb, program|void arrayb, mapping(int:object) generics) {
    return .JSONTokener(json, objectb, arrayb, generics)->nextObject();
}

String.Buffer serialize(object|mapping|array|string|int|float thing,
			String.Buffer|void sb, string|void newline) {
#if 0
#if constant(Public)
# if constant(Public.Parser)
#  if constant(Public.Parser.JSON)
    string res;

    res = Public.Parser.JSON.serialize(thing);
    if (newline) res = replace(res, "\n", newline);
    if (!sb) sb = String.Buffer(sizeof(res));
    sb->add(res);

    return sb;
#  endif
# endif
#endif
#endif

    serialize_pike(thing, sb, newline);
}

String.Buffer serialize_pike(object|mapping|array|string|int|float thing,
			     String.Buffer|void sb, string|void newline) {
    return .JSONSerializer(thing, sb, newline)->_sb;
}
