
object gen_vars(mapping params) {
	mapping v = params["mandatory"];
	mapping ov = params["optional"];
	string type = params["type"] || "_vars";
	string t = "";
	mapping types = (v||([])) + (ov||([]));
	object def = m_delete(types, "_");
	int min_len = 2, max_len = 2;

	t += sprintf("string type = %O;", type);
	foreach (types; string m;) {
		min_len = min(sizeof(MMP.abbreviations(m)), min_len);
		max_len = max(sizeof(MMP.abbreviations(m)), max_len);
		t += "object type"+m+";";
	}
	if (def) t += "object def;";


	t += #"
mixed decode(Serialization.Atom a) {
    if (has_index(a->typed_data, this)) return a->typed_data[this];
    object p = Serialization.AtomParser();
    p->feed(a->data);
    mapping m = ([]);
KEY: while (p->left()) {
	    string k = p->parse_method();
	    Serialization.Atom atom = p->parse();
	    if (!k || !atom) error(\"Malformed _vars in %O\\n\", a);
";

	if (sizeof(types)) {
		t+="array(string) a = MMP.abbreviations(k);\n";
		t+=sprintf("for (int i = min(sizeof(a)-1, %d); i >= max(1, %d); i--) {\n", max_len - 1, min_len - 1);
		t+= "		string key = a[i];\n";
		t += #"
			switch (key) {
";
		foreach (types; string m;) {
			t += "case \""+m+"\": m[k] = type"+m+"->decode(atom); continue KEY;\n";
		}
		t+= "		}\n		}\n";
	}
	if (def) {
		t += "m[k] = def->decode(atom);";
	} else {
		t+="error(\"Cannot decode atom %O:%O in %O\\n\", k, atom, a);";
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
KEY: foreach(m; string k; mixed val) {";
	if (sizeof(types)) {
		t+="array(string) a = MMP.abbreviations(k);\n";
		t+=sprintf("for (int i = min(sizeof(a)-1, %d); i >= max(1, %d); i--) {\n", max_len - 1, min_len - 1);
		t+= "		string key = a[i];\n";
		t += #"
			switch (key) {
";
		foreach (types; string m;) {
			t += "case \""+m+"\": buf->add(k+\" \"); type"+m+"->render(val, buf); continue KEY;";
		}
		t+= "		}\n		}\n";
	}
	if (def) {
		t += "buf->add(k+\" \"); def->render(val, buf);\n";
	} else {
		t+="error(\"Cannot encode %O:%O in %O\\n\", k, val, a);";
	} 
	t+= #"}\nreturn buf->get();
	}
	Serialization.StringBuilder render(mapping m, Serialization.StringBuilder buf) {
		 	int|array node = buf->add();
		 	int length = buf->length();
KEY: foreach(m; string k; mixed val) {"; 
	if (sizeof(types)) {
		t+="array(string) a = MMP.abbreviations(k);\n";
		t+=sprintf("for (int i = min(sizeof(a)-1, %d); i >= max(1, %d); i--) {\n", max_len - 1, min_len - 1);
		t+= "		string key = a[i];\n";
		t += #"
			switch (key) {
";
		foreach (types; string m;) {
			t += "case \""+m+"\": buf->add(k+\" \"); type"+m+"->render(val, buf); continue KEY;";
		}
		t+= "		}\n		}\n";
	}
	if (def) {
		t += "buf->add(sprintf(\"%s \", k)); buf->add(def->encode(val)->render());\n";
	} else {
		t+="error(\"Cannot encode %O:%O in %O\\n\", k, val, a);";
	} 
	t+= #"}
	buf->set_node(node, sprintf(\"%s %d \", type, buf->length() - length));
	return buf;
}

	int(0..1) can_encode(mixed a) { return mappingp(a); }
	int(0..1) can_decode(Serialization.Atom a) { return a->type == type; }
";
	t += sprintf("string _sprintf(int type) { return %O; }\n", sprintf("MappingType(%O, %O)", types, def));

#if 0
	foreach (t/"\n"; int i; string line) {
		werror("%d:  %s\n", i+1, line);
	}
#endif
	program p;
	mixed err = catch {
	    p = compile(t);
	};

	if (err) {
	    	
		werror("compile error %s in:\n", describe_error(err));
		foreach (t/"\n"; int i; string line) {
		    werror("%d:  %s\n", i+1, line);
		}

		throw(err);	
	}

	object o = p();
	foreach (types; string m; object type) {
		o["type"+m] = type;
	}
	if (def) o["def"] = def;

	return o;
}
