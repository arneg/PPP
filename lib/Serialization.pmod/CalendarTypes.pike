import Serialization.Types;

object Timerange() {
    object o;

    if (!(o = this->type_cache[App.Types.Timerange][0])) {
	o = App.Types.Timerange(type_cache);
	this->type_cache[App.Types.Timerange][0] = o;
    }

    return o;
}

object Ruleset() {
    object o;

    if (!(o = this->type_cache[App.Types.Ruleset][0])) {
	o = App.Types.Ruleset(type_cache);
	this->type_cache[App.Types.Ruleset][0] = o;
    }

    return o;
}
