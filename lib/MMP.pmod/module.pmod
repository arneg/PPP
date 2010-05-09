// vim:syntax=lpc

constant DEFAULT_PORT = 4044;

//! @returns
//!	@int
//!	    @value 0
//!		@expr{var@} is not an MMP variable.
//!	    @value 1
//!		@expr{var@} is an MMP variable that should be seen
//!		by the application layer.
//!	    @value 2
//!		@expr{var@} is an MMP variable that should be used
//!		by the routing layer of your program only.
//!	@endint
//! @seealso
//!	For a description of MMP variables see @[http://psyc.pages.de/mmp.html].
int(0..2) is_mmpvar(string var) {
    switch (var) {
    case "_target":
    case "_target_relay":
    case "_source":
    case "_source_relay":
    case "_source_location":
    case "_source_identification":
    case "_context":
    case "_length":
    case "_counter":
    case "_reply":
    case "_trace":
    case "_amount_fragments":
    case "_fragment":
		return 1;
    case "_encoding":
    case "_list_require_modules":
    case "_list_require_encoding":
    case "_list_require_protocols":
    case "_list_using_protocols":
    case "_list_using_modules":
    case "_list_understand_protocols":
    case "_list_understand_modules":
    case "_list_understand_encoding":
		return 2;
    }

    return 0;
}


//! @returns
//! @int
//! 	@value 1
//! 		@expr{o@} is a @[Uniform].
//! 	@value 0
//! 		@expr{o@} is not a @[Uniform].
//! @endint
int(0..1) is_uniform(mixed o) {
    if (objectp(o) && Program.inherits(object_program(o), MMP.Uniform)) {
	return 1;
    } else {
	return 0;
    }
}

//! @returns
//! @int
//! 	@value 1
//! 		@expr{o@} is a MMP.Uniform designated by @expr{designator@}
//! 	@value 0
//! 		@expr{o@} is not a Person.
//! @endint
//!
//! @seealso
//!	@[is_person()], @[is_place()], @[is_uniform()]
int(0..1) is_thing(mixed o, int designator) {
    return is_uniform(o) && stringp(o->resource) && sizeof(o->resource) && o->resource[0] == designator;
}

//! @returns
//! @int
//! 	@value 1
//! 		@expr{o@} is a Person (designated by an '~' in MMP/PSYC).
//! 	@value 0
//! 		@expr{o@} is not a Person.
//! @endint
//!
//! @seealso
//!	@[is_thing()], @[is_place()], @[is_uniform()]
int(0..1) is_person(mixed o) {
    return is_thing(o, '~');
}

//! @returns
//! @int
//! 	@value 1
//! 		@expr{o@} is a Place (designated by an '@@' in MMP/PSYC).
//! 	@value 0
//! 		@expr{o@} is not a Place.
//! @endint
//! @seealso
//!	@[is_thing()], @[is_person()], @[is_uniform()]
int(0..1) is_place(mixed o) {
    return is_thing(o, '@');
}

array(string) abbreviations(string m) {
	array(string) a = m / "_";

	if (sizeof(a[0]) && sizeof(a) < 2) error("Invalid method: %O\n", m);

	for (int i = 1; i < sizeof(a); i++) a[i] = a[i-1] + "_" + a[i];
	a[0] = "_";

	return a;
}
