
object gen_vars(mapping params) {
	mapping v = params["mandatory"];
	mapping ov = params["optional"];
	string type = params["type"] || "_vars";
	string t = "";
	mapping types = (v||([])) + (ov||([]));
	object def = m_delete(types, "_");

	t += sprintf("string type = %O;", type);
	foreach (types; string m;) {
		t += "object type"+m+";";
	}
	if (def) t += "object def;";

	t += "mixed decode(Serialization.Atom a) {";
	t += "if (has_index(a->typed_data, this)) return a->typed_data[this];";
	t += "array list = Serialization.parse_atoms(a->data);";
	t += "if (sizeof(list) & 1) error(\"Cannot decode mapping with odd number of entries.\\n\");";
	t += "for (int i = 0; i < sizeof(list); i+=2)";
	if (sizeof(types)) {
		t += "switch (list[i]->data) {";
		foreach (types; string m;) {
			t += "case \""+m+"\": list[i] = \""+m+"\"; list[i+1] = type"+m+"->decode(list[i+1]); break;";
		}
		t += "default:";
	} else {
		t += "{";
	}
	if (def) {
		t += "list[i] = list[i]->data; list[i+1] = def->decode(list[i+1]); }";
	} else {
		t += "}";
		//t+="error(\"Cannot decode atom %O:%O in %O\\n\", list[i], list[i+1], a);}";
	} 
	t += "mapping m = aggregate_mapping(@list);";
	t+= "a->set_typed_data(this, m);";
	t+= "return m;}";

	t += "Serialization.Atom encode(mapping m) {"
		 "	Serialization.Atom a = Serialization.Atom(type, 0);"
		 "	a->set_typed_data(this, m);"
		 "  return a;}"
		 "string render_payload(Serialization.Atom a) {"
		 "	mapping m = a->typed_data[this];"
		 "	MMP.Utils.StringBuilder buf = MMP.Utils.StringBuilder();"
		 "	array node = buf->add();"
		 "	foreach(m; string key; mixed val)";
	if (sizeof(types)) {
		t += "switch (key) {";
		foreach (types; string m;) {
			t += "case \""+m+"\": buf->add(\"_method "+(string)sizeof(m)+" "+m+"\"); type"+m+"->render(val, buf); break;";
		}
		t+="default:";
	} else {
		t += "{";
	}
	if (def) {
		t += "buf->add(sprintf(\"_method %d %s\", sizeof(key), key)); buf->add(def->encode(val)->render());}";
	} else {
		t += "}";
		//t += "werror(\"Cannot encode %O:%O in %O\\n\", key, val, m);}";
	}
	t+= "return buf->get();";
	t+= "}";
	t+= "MMP.Utils.StringBuilder render(mapping m, MMP.Utils.StringBuilder buf) {"
		 "	array node = buf->add();"
		 "	int length = buf->length();"
		 "	foreach(m; string key; mixed val)";
	if (sizeof(types)) {
		t += "switch (key) {";
		foreach (types; string m;) {
			t += "case \""+m+"\": buf->add(\"_method "+(string)sizeof(m)+" "+m+"\"); type"+m+"->render(val, buf); break;";
		}
		t+="default:";
	} else {
		t += "{";
	}
	if (def) {
		t += "buf->add(sprintf(\"_method %d %s\", sizeof(key), key)); buf->add(def->encode(val)->render());}";
	} else {
		t += "}";
		//t += "werror(\"Cannot encode %O:%O in %O\\n\", key, val, m);}";
	}
	t+= "buf->set_node(node, sprintf(\"%s %d \", type, buf->length() - length));";
	t+= "return buf;";
	t+= "}";

	t += "int(0..1) can_encode(mixed a) { return mappingp(a); }";
	t += "int(0..1) can_decode(Serialization.Atom a) { return a->type == type; }";
	t += sprintf("string _sprintf(int type) { return %O; }", sprintf("MappingType(%O, %O)", types, def));
	program p = compile(t);
	object o = p();
	foreach (types; string m; object type) {
		o["type"+m] = type;
	}
	if (def) o["def"] = def;

	return o;
}
