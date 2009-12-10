import Serialization.Types;

inherit Serialization.BasicTypes;

object Vars(void|mapping(string:object) m, void|mapping(string:object) m2) {
	return gen_vars(m, m2);
    // get a better mangler
    int a = (mappingp(m)) ? sizeof(m)*2 : 0;
    int b = (mappingp(m2)) ? sizeof(m2)*2 : 0;
    array args = allocate(a + b);

    if (a) foreach (sort(indices(m));int i; string ktype) {
		args[i] = ktype;
		args[i+1] = m[ktype];
    }

    if (b) foreach (sort(indices(m2));int i; string ktype) {
		i+=a;
		args[i] = ktype;
		args[i+1] = m2[ktype];
    }

    object mangler = Serialization.Mangler(args);
    object method = Method(), o;

    if (!(o = this->type_cache[Serialization.Types.Vars][mangler])) {
		o = Serialization.Types.Vars(method, m, m2);
		this->type_cache[Serialization.Types.Vars][mangler] = o;
    }

    return o;
}

object Method(string|void base) {
    object method;
    if (!base) base = 0;

    if (!(method = this->type_cache[Serialization.Types.Method][base])) {
		method = Serialization.Types.Method(base);
		this->type_cache[Serialization.Types.Method][base] = method;
    }
    
    return method;
}

object Uniform() {
	object u; 

	if (!this->server) {
		error("No Uniform creator without server.\n");
	}

    if (!(u = this->type_cache[Serialization.Types.Uniform][this->server])) {
		u = Serialization.Types.Uniform(this->server);
		this->type_cache[Serialization.Types.Method][this->server] = u;
    }
    
    return u;
}

/*
object PsycPacket(string base, void|object data, void|mapping m, void|mapping m2) {
    object method, vars;
    object o;

    if (m || m2) vars = Vars(m, m2);

    method = Method(base);
     
    object mangler = Serialization.Mangler(({ method, data, vars }));
    
    if (!(o = this->type_cache[Serialization.Types.PsycPacket][mangler])) {
		o = Serialization.Types.PsycPacket(method, vars, data);
		this->type_cache[Serialization.Types.PsycPacket][mangler] = o;
    }

    return o;
}
*/

object Packet(object type) {
    object o;

	if (!type) type = Atom();
     
    if (!(o = this->type_cache[Serialization.Types.Packet][type])) {
		object vars = Vars(0, ([
			"_id" : Int(),
			"_source" : Uniform(),
			"_target" : Uniform(),
			"_context" : Uniform(),
			"_timestamp" : Time(),
		]));

		o = Serialization.Types.Packet(type, vars);
		this->type_cache[Serialization.Types.Packet][type] = o;
    }

    return o;
}

object gen_vars(void|mapping(string:object) v, void|mapping(string:object) ov) {
	string t = "";
	mapping types = (v||([])) + (ov||([]));
	object def = m_delete(types, "_");

	t += "string type = \"_vars\";";
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
		t+="error(\"Cannot decode atom %O:%O in %O\\n\", list[i], list[i+1], a);}";
	} 
	t += "mapping m = aggregate_mapping(@list);";
	t+= "a->set_typed_data(this, m);";
	t+= "return m;}";

	t += "Serialization.Atom encode(mapping m) {"
		 "	Serialization.Atom a = Serialization.Atom(\"_vars\", 0);"
		 "	a->set_typed_data(this, m);"
		 "  return a;}"
		 "string to_raw(Serialization.Atom a) {"
		 "	mapping m = a->typed_data[this];"
		 "	String.Buffer buf = String.Buffer();"
		 "	foreach(m; string key; mixed val)";
	if (sizeof(types)) {
		t += "switch (key) {";
		foreach (types; string m;) {
			t += "case \""+m+"\": buf->add(\"_method "+(string)sizeof(m)+" "+m+"\"); buf->add(type"+m+"->encode(val)->render()); break;";
		}
		t+="default:";
	} else {
		t += "{";
	}
	if (def) {
		t += "buf->add(sprintf(\"_method %d %s\", sizeof(key), key)); buf->add(def->encode(val)->render());}";
	} else {
		t += "error(\"Cannot encode %O:%O in %O\\n\", key, val, m);}";
	}
	t+= "a->data = buf->get();";
	t+= "return a->render(); }";

	t += "int(0..1) can_encode(mixed a) { return mappingp(a); }";
	t += "int(0..1) can_decode(Serialization.Atom a) { return a->type == \"_vars\"; }";
	t += "string _sprintf(int type) { return \"MappingType("+sizeof(types)+")\"; }";
	program p = compile(t);
	werror("");
	object o = p();
	foreach (types; string m; object type) {
		o["type"+m] = type;
	}
	if (def) o["def"] = def;

	return o;
}
