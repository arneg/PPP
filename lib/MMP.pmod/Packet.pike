//! Implementation of an MMP Packet as descibed in 
//! @[http://about.psyc.eu/MMP].


//! MMP Variables of the Packet. These variables are routing information.
//! You can find a description of all variables and their meaning in
//! @[http://psyc.pages.de/mmp.html].
mapping(string:mixed) vars;
mapping misc = set_weak_flag(([]), Pike.WEAK);

//! Data contained in the Packet. Could be a @expr{string@} of arbitrary
//! data or an object. Objects are expected to be subclasses of 
//! @[PSYC.Packet] in many parts of the @[PSYC] code.
string|object data;

function parsed = 0, sent = 0; 
#ifdef LOVE_TELNET
string newline;
#endif

// experimental variable family inheritance...
// this actually does not exactly what we want.. 
// because asking for a _source should return even _source_relay 
// or _source_technical if present...
void create(object data, void|mapping(string:mixed) vars) {
	if (mappingp(vars)) {
		this_program::vars = has_index(vars, "_timestamp") ? vars : vars + ([ "_timestamp" : Calendar.now() ]);
	} else this_program::vars = ([ "_timestamp" : Calendar.now() ]);
	this_program::data = data||0; 
}

string next() {
	return (string)this;
}

int has_next() { 
	return 0;
}

//! @returns
//!	    A string representation of the unique Packet identification
//!	    as described in @[http://www.psyc.eu/mmp.html].
string id() {
	if (has_index(vars, "_context")) {
		return (string)vars["_context"] + (string)vars["_counter"];
	}
	return (string)vars["_source"] + (string)vars["_target"] + (string)vars["_counter"];
}

string _sprintf(int type) {
	if (type == 'O') {
		if (data == 0) {
			return "MMP.Packet(Empty)\n";
		}

		if (stringp(data)) {
		return sprintf("MMP.Packet(%O, '%.15s..' )\n", vars, data);
		} else {
#if defined(DEBUG) && DEBUG > 2
		return sprintf("MMP.Packet(\n\t_target: %s\n\t_source: %s\n\t_context: %s | %O)\n", vars["_target"]||"0", vars["_source"]||"0", vars["_context"]||"0", data);
#else
		return sprintf("MMP.Packet(%O, %O)\n", vars, data);
#endif
		}
	}

	return UNDEFINED;
}

//! @returns
//!	    The value of the variable @expr{id@}. In case the packet contains
//!	    an object e.g., a @[PSYC.Packet], variables of the object may be
//!	    accessed this way aswell.
mixed `[](string id) {
	if (has_index(vars, id)) {
		return vars[id];
	}

	if (!MMP.is_mmpvar(id) && objectp(data)) {
		//P3(("MMP.Packet", "Accessing non-mmp variable (%s) in an mmp-packet.\n", id))
		return data[id];
	}

	return UNDEFINED;
}

//! Assign MMP variable @expr{id@} to @expr{val@}.
//! @returns
//!	    @expr{val@}
//! @throws
//!	    This method throws if @expr{id@} is not a MMP variable and the packet
//!	    does not contain an object.
mixed `[]=(string id, mixed val) {

	if (MMP.is_mmpvar(id)) {
		return vars[id] = val;
	}
	
	if (objectp(data)) {
		return data[id] = val;
	}

	error("put psyc variable (%s) into mmp packet (%O).", id, this);
}

#if 0
mixed `->(mixed id) {
	switch(id) {
		case "lsource":
			if (has_index(vars, "_source_relay")) {
				mixed s = vars["_source_relay"];

				if (arrayp(s)) {
					s = s[-1];
				}

				return s;
			}
		case "source":
			if (has_index(vars, "_source_identification")) {
				return vars["_source_identification"];
			}

			return vars["_source"];
	}

	return ::`->(id);
}
#endif

//! @returns
//!	    The target of this packet i.e., the Uniform of the entity this 
//!	    Packet is addressed to.
MMP.Uniform target() {
	return vars["_target"];
}

//! @returns
//!	    The source of this packet i.e., the Uniform of the entity this 
//!	    Packet originates from. This is not to be confused with the 
//!	    technical source.
//! @note
//!	    @expr{_source_identification || _source@}
MMP.Uniform source() {
	if (has_index(vars, "_source_identification")) {
		return vars["_source_identification"];
	}

	return vars["_source"];
}

//! @returns
//!	    The reply adress of this packet i.e., the Uniform of the entity
//!	    that is meant to receive any reply to this Packet.
//! @note
//!	    @expr{_source_identification_reply || _source_reply || _source@}
//! @seealso
//!	    @[PSYC.Packet()->reply()]
//! @example
//!	    PSYC.Packet m = p->data; 
//!	    sendmsg(p->reply(), m->reply("_notice_version"));
MMP.Uniform reply() {
	return vars["_source_identification_reply"]
		|| vars["_source_reply"]
		|| vars["_source"];
}

//! @returns
//!	    Returns the relay source of this packet, @[source()] otherwise.
MMP.Uniform lsource() {
	if (has_index(vars, "_source_relay")) {
		mixed s = vars["_source_relay"];

		if (arrayp(s)) {
			s = s[-1];
		}

		return s;
	}

	return source();
}

//! @returns
//!	    Returns the technical source of this packet, which is either 
//!     _source or _context.
MMP.Uniform tsource() {
	return vars["_source"] || vars["_context"];
}

// why do we need this? copy_value doesn't copy objects.
//! Clones the @[Packet] - this basically means that a new @[Packet] with
//! identical data and a first level copy of vars (@expr{vars + ([ ])@})
//! is created and returned.
//!
//! @[Packets] may not be modified once they have been sent (if you
//! received a @[Packet], someone else sent it to you...), so you need to
//! clone it before you do any modifications.
//!
//! @seealso
//!	    @[PSYC.Packet()->clone()]
this_program clone() {
	return this_program(data, vars + ([ ]));
}
