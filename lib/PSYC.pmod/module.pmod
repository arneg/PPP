// vim:syntax=lpc
// put that somewhere else.. maybe
//
constant GOON = 0;
constant STOP = 1;
constant WAIT = 2;


//! This module contains modules and classes for participating in the PSYC!
//! world. See http://about.psyc.eu/ for more information about PSYC.
//! 
//! PSYC is a messaging protocol that handles communication of PSYC entities 
//! i.e., persons and chatrooms. There are other entities currently in use 
//! which will be talked about later. See @[PSYC.Person] and @[PSYC.Place].
//! 
//! PSYC entities are identified using their unique uniform. These uniforms are 
//! adresses similar to URLs. A detailed description of uniforms can be found 
//! at @[http://www.psyc.eu/unl.html]. For convenience we use objects internally
//! instead of string representations of uniforms. That way it is much easier to
//! access certain parts of uniforms. See @[MMP.Uniform] for a documentation
//! on those.
//!
//! Communication of PSYC entities is managed by one central object. Currently 
//! there exists only one such class, namely @[PSYC.Server]. There are plans to
//! implement more lightweight ones for simple applications.

class Dummy(mixed...params) { }

//! Checks whether a PSYC mc is a generalization of another one.
//! @returns
//!	@int
//!		@value 0
//!			@expr{needle@} is not an abbreviation of @expr{haystack@}.
//!		@value 1
//!			@expr{needle@} is an abbreviation of @expr{haystack@}.
//!	@endint
int(0..1) abbrev(string haystack, string needle) {
    if (haystack == needle) return 1;

    if (sizeof(needle) < sizeof(haystack)) return 0;

    if (haystack[..sizeof(needle)-1] != needle) return 0;

    if (haystack[sizeof(needle)] == '_') return 1;

    return 0;
}

//! Renders packets into neat strings based on templates either provided by the @[Packet] or the @[Text.TextDB].
string psyctext(MMP.Packet p, PSYC.Text.TextDB db) {
    mapping v;
    string tmp;
    int is_message;

    if (equal(p->data->mc / "_", ({ "", "message" }))) {
	is_message = 1;
    }

    if (p->vars) {
	v = ([]);
	v += p->vars;
    }

    if (p->data && p->data->vars) {
	if (!v) v = ([]);
	v += p->data->vars;
    }

    if (is_message && p->data->data) {
	if (!v) v = ([]);
	v["_data"] = p->data->data;
    }

    tmp = db[p->data->mc] || (is_message ? "[_data]" : p->data->data);

    if (v && tmp) {
	return PSYC.Text.psyctext(tmp, v);
    }

    return tmp || p->data->mc;
}

