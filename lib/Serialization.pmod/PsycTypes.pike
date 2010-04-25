//vim:syntax=lpc
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
    object o;

    if (1 || !(o = this->type_cache[object_program(mangler)][mangler])) {
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
		    this->type_cache[Serialization.Types.Uniform][this->server] = u;
	}

	return u;
}

object default_polymorphic(void|object index) {
    if (!index) index = Serialization.Mangler(({ this->server }));
    object o = ::default_polymorphic(index);
    if (!has_index(o->ptypes, MMP.Uniform)) o->register_type(MMP.Uniform, "_uniform", Uniform());
    return o;
}


object Message(void|object data, void|mapping m, void|mapping m2) {
    object vars;
    object o;

    if (!data) data = UTF8String();

    if (m || m2) vars = Vars(m, m2);

    object mangler = Serialization.Mangler(({ data, vars, this->server }));
    
    if (!vars) vars = Vars(0, ([ "_" : default_polymorphic() ]));

    if (!(o = this->type_cache[Serialization.Types.Message][mangler])) {
		o = Serialization.Types.Message(vars, data);
		this->type_cache[Serialization.Types.Message][mangler] = o;
    }

    return o;
}

object Packet(object type) {
    object o;

    if (!type) type = Atom();

    object mangler = Serialization.Mangler(({ type, this->server }));
     
    if (!(o = this->type_cache[Serialization.Types.Packet][mangler])) {
	object uniform = Uniform();
	object integer = Int();
	object vars = Vars(0, ([
		"_id" : integer,
		"_ack" : integer,
		"_sequence_max" : integer,
		"_sequence_pos" : integer,
		//"_hrtime" : integer,
		"_source" : uniform,
		"_target" : uniform,
		"_context" : uniform,
		"_source_relay" : uniform,
		"_timestamp" : Time(),
	]));

	o = Serialization.Types.Packet(type, vars);
	this->type_cache[Serialization.Types.Packet][mangler] = o;
    }

    return o;
}
