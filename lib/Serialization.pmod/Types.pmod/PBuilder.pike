// set of supported atom types
mapping atypes = ([]);
// set of supported pike type, either basetype() or object_program()
// we could think about supporting inheritance at some point
mapping ptypes = ([]);
int types = 0;

string register_type(string|program ptype, string atype) {
	string name = sprintf("t%d", types++);

    if (!has_index(ptypes, ptype)) {
		ptypes[ptype] = ({ name });
    } else {
		ptypes[ptype] += ({ name });
    }

    array t = atypes[atype];

    if (t) {
		atypes[atype] += ({ name });
    } else {
		atypes[atype] = ({ name });
    }

	return name;
}

#define DECODE(atype, i)	(sprintf("type%s_%d", atype, i))
#define PNAME(program,i)	("ptype_" + (stringp(program) ? program : replace(sprintf("%O", program), ({ ".", "(", ")", "-", ">" }), "_")) + (string)i)

object optimize() {
	string ret = "";
	for (int i = 0; i < types; i++) {
		ret +=	sprintf("object t%d;\n", i);
	}

	ret +=	"\n\nint(0..1) can_decode(Serialization.Atom a) {\n"
			"switch (a->type) {\n";
	foreach (atypes;string method;array t) {
		ret +=	sprintf("case %O:\n", method);
	}
	ret += "	 	return 1;\n"
		   "} return 0; }"
		"\n\nmixed decode(Serialization.Atom a) {\n"
			"switch (a->type) {\n";
	foreach (atypes;string method;array t) {
			ret +=	sprintf("case %O:\n", method);
		foreach (t;int i;string var) {
			ret +=	sprintf("\tif (%s->can_decode(a)) return %s->decode(a);\n", var, var);
		}
		ret += "break;\n";
	}
	ret += "} error(\"cannot decode %O\\n\", a); }\n"
		"\n\nint(0..1) can_encode(mixed v) {\n"
			"switch (objectp(v) ? object_program(v) : basetype(v)) {\n";
	foreach (ptypes;string|program p;array types) {
		ret += sprintf("case %O:\n", p);
	}
	ret +=	" return 1; "
			" } "
		"return 0; }"
		"\n\nSerialization.Atom encode(mixed v) {\n"
			"switch (objectp(v) ? object_program(v) : basetype(v)) {\n";
	foreach (ptypes;string|program p;array types) {
		ret += sprintf("case %O:\n", p);
		foreach (types;int i;string var) {
			ret += sprintf("if (%s->can_encode(v)) return %s->encode(v);\n", var, var);
		}
		ret += "break;\n";
	}
	ret +=	" } ";
	ret += "error(\"cannot encode cannot %O\\n\", v); }"
		   "\n\nSerialization.StringBuilder render(mixed v, Serialization.StringBuilder buf) {\n"
			"switch (objectp(v) ? object_program(v) : basetype(v)) {\n";
	foreach (ptypes;string|program p;array types) {
		ret += sprintf("case %O:\n", p);
		foreach (types;int i;string var) {
			ret += sprintf("if (%s->can_encode(v)) return %s->render(v, buf);\n", var, var);
		}
		ret += "break;\n";
	}
	ret +=	" } ";
	ret += "error(\"cannot render %O\\n\", v); }";

	object o = (compile_string(ret))();

	return o;
}
