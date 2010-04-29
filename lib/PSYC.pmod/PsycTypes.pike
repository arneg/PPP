//vim:syntax=lpc
import Serialization.Types;
inherit Serialization.BasicTypes;

object Uniform() {
	object u; 

	if (!this->server) {
		error("No Uniform creator without server.\n");
	}

	if (!(u = this->type_cache[MMP.Types.Uniform][this->server])) {
		    u = MMP.Types.Uniform(this->server);
		    this->type_cache[MMP.Types.Uniform][this->server] = u;
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

    if (!(o = this->type_cache[PSYC.Types.Message][mangler])) {
		o = PSYC.Types.Message(vars, data);
		this->type_cache[PSYC.Types.Message][mangler] = o;
    }

    return o;
}

object Packet(object type) {
    object o;

    if (!type) type = Atom();

    object mangler = Serialization.Mangler(({ type, this->server }));
     
    if (!(o = this->type_cache[MMP.Types.Packet][mangler])) {
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

	o = MMP.Types.Packet(type, vars);
	this->type_cache[MMP.Types.Packet][mangler] = o;
    }

    return o;
}
