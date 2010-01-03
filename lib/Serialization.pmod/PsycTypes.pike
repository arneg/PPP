import Serialization.Types;

inherit Serialization.BasicTypes;

object Vars(void|mapping(string:object) m, void|mapping(string:object) m2) {
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

    if (!(o = this->type_cache[object_program(mangler)][mangler])) {
		o = Serialization.Types.gen_vars(([ "mandatory" : m, "optional" : m2 ]));
		this->type_cache[object_program(mangler)][mangler] = o;
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
			//"_hrtime" : Int(),
			"_source" : Uniform(),
			"_target" : Uniform(),
			"_context" : Uniform(),
			"_source_relay" : Uniform(),
			"_timestamp" : Time(),
		]));

		o = Serialization.Types.Packet(type, vars);
		this->type_cache[Serialization.Types.Packet][type] = o;
    }

    return o;
}
