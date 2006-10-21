// $Id: module.pmod,v 1.1 2006/10/21 23:30:16 tobij Exp $

mixed decode_json(string json, program|void objectb, program|void arrayb) {
    return .JSONTokener(json, objectb, arrayb)->nextObject();
}
