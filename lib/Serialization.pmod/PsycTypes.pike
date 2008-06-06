import Serialization.Types;

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
	args[i+1] = m[ktype];
    }

    object mangler = Serialization.Mangler(args);
    object method, o;

    if (!(method = this->type_cache[String][0])) {
	method = String();
	this->type_cache[String][0] = o;
    }

    if (!(o = this->type_cache[Serialization.Types.Vars][mangler])) {
	o = Serialization.Types.Vars(method, m, m2);
	this->type_cache[Serialization.Types.Vars][mangler] = o;
    }

    return o;
}
