inherit Serialization.Types.Base;
inherit Serialization.BasicTypes;
inherit Serialization.PsycTypes;
//inherit Serialization.Signature;

object list;

void create(object typecache) {
    Serialization.Types.Base::create("_ruleset_calendar");
   // Serialization.Signature::create(typecache);

    

}

int decode(Serialization.Atom a) {
    if (can_decode(a)) {
	string tz = a->data;
	object rule = Calendar.Ruleset();
	rule->set_timezone(Calendar.Timezone[tz]);

	return rule;
    }

    throw(({}));
}

Serialization.Atom encode(object ruleset) {
    object a = Serialization.Atom("_ruleset_calendar", ruleset->timezone->zoneid);
    return a;
}

int(0..1) can_encode(mixed a) {
    return Program.inherits(object_program(a), Calendar.Ruleset);
}

