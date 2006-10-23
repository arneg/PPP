// $Id: module.pmod,v 1.2 2006/10/23 18:20:48 tobij Exp $

mixed parse(string json, program|void objectb, program|void arrayb) {
#if constant(Public)
# if constant(Public.Parser)
#  if constant(Public.Parser.JSON)
    if (!(objectb || arrayb)) {
	return Public.Parser.JSON.parse(json);
    }
#  endif
# endif
#endif

    return .JSONTokener(json, objectb, arrayb)->nextObject();
}

mixed parse_pike_only(string json, program|void objectb, program|void arrayb) {
    return .JSONTokener(json, objectb, arrayb)->nextObject();
}
