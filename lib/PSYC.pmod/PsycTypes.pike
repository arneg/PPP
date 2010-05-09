//vim:syntax=lpc
inherit MMP.MmpTypes;

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
