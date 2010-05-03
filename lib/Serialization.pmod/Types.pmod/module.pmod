
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

	t += #"
mixed decode(Serialization.Atom a) {
    if (has_index(a->typed_data, this)) return a->typed_data[this];
    object p = Serialization.AtomParser();
    p->feed(a->data);
    mapping m = ([]);
    while (p->left()) {
	    string key = p->parse_method();
	    Serialization.Atom atom = p->parse();
	    if (!key || !atom) error(\"Malformed _vars in %O\\n\", a);
";
	if (sizeof(types)) {
		t += #"
	switch (key) {
";
		foreach (types; string m;) {
			t += "case \""+m+"\": m[key] = type"+m+"->decode(atom); break;";
		}
		t += "default:";
	}
	if (def) {
		t += "m[key] = def->decode(atom);";
	} else {
		t += "}";
		//t+="error(\"Cannot decode atom %O:%O in %O\\n\", list[i], list[i+1], a);}";
	} 
	t+= #"
    }
    a->set_typed_data(this, m);
    return m;
}

Serialization.Atom encode(mapping m) {
    Serialization.Atom a = Serialization.Atom(type, 0);
    a->set_typed_data(this, m);
    return a;
}
string render_payload(Serialization.Atom a) {
    mapping m = a->typed_data[this];
    Serialization.StringBuilder buf = Serialization.StringBuilder();
    array node = buf->add();
    foreach(m; string key; mixed val)";
	if (sizeof(types)) {
		t += "switch (key) {";
		foreach (types; string m;) {
			t += "case \""+m+"\": buf->add(\""+m+" \"); type"+m+"->render(val, buf); break;";
		}
		t+="default:";
	} else {
		t += "{";
	}
	if (def) {
		t += "buf->add(sprintf(\"%s \", key)); buf->add(def->encode(val)->render());}";
	} else {
		t += "}";
		//t += "werror(\"Cannot encode %O:%O in %O\\n\", key, val, m);}";
	}
	t+= #"return buf->get();
	}
	Serialization.StringBuilder render(mapping m, Serialization.StringBuilder buf) {
		 	int|array node = buf->add();
		 	int length = buf->length();
		 	foreach(m; string key; mixed val)";
	if (sizeof(types)) {
		t += "switch (key) {";
		foreach (types; string m;) {
			t += "case \""+m+"\": buf->add(\""+m+" \"); type"+m+"->render(val, buf); break;";
		}
		t+="default:";
	} else {
		t += "{";
	}
	if (def) {
		t += "buf->add(key+\" \"); def->render(val, buf);}";
	} else {
		t += "}";
		//t += "werror(\"Cannot encode %O:%O in %O\\n\", key, val, m);}";
	}
	t+= #"
	buf->set_node(node, sprintf(\"%s %d \", type, buf->length() - length));
	return buf;
}

	int(0..1) can_encode(mixed a) { return mappingp(a); }
	int(0..1) can_decode(Serialization.Atom a) { return a->type == type; }
";
	t += sprintf("string _sprintf(int type) { return %O; }\n", sprintf("MappingType(%O, %O)", types, def));
	program p;
	mixed err = catch {
	    p = compile(t);
	};

	if (err) {
	    	
		werror("compile error %s in:\n", describe_error(err));
		foreach (t/"\n"; int i; string line) {
		    werror("%d:  %s\n", i+1, line);
		}
	}

	object o = p();
	foreach (types; string m; object type) {
		o["type"+m] = type;
	}
	if (def) o["def"] = def;

	return o;
}
