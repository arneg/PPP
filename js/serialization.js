/*
Copyright (C) 2008-2009  Arne Goedeke

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
version 2 as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/
serialization = {};
/**
 * Atom class.
 * @constructor
 * @param {String} type Atom type, e.g. _integer
 * @param {String} data String representation of the value
 * @property {String} type Atom type, e.g. _integer.
 * @property {String} data String representation of the value
 */
serialization.Atom = Base.extend({
	constructor : function(type, data) {
		this.type = type;
		this.data = data;
	},
	/**
	 * @returns The serialized atom.
	 */
	render : function() {
		return this.type + " " + new String(this.data.length) + " " + this.data;
    },
	length : function() {
		return this.type.length + new String(this.data.length).length 
			+ this.data.length + 2;
    },
	toString : function() {
		return "Atom("+this.type+", "+this.data+")";
	}
});
/**
 * Atom parser class.
 * @constructor
 */
serialization.AtomParser = Base.extend({
	constructor : function() {
		this.buffer = "";
		this.reset();
	},
	reset : function() {
		this.type = 0;
		this.length = -1;
	},
	/**
	 * Parse one or more Atom objects from a string.
	 * @returns An array of serialization#Atom objects.
	 * @param {String} str Input string that to parse.
	 */
	parse : function(str) {
		this.buffer += str;

		var ret = new Array();
		var t = 0;
		while (t = this._parse()) {
			ret.push(t);
		}
		return ret;
	},
	_parse : function() {
		if (!this.type) {
			var pos = this.buffer.indexOf(" ");

			if (pos == -1) {
			// check here for bogus data
	//		if (re[0].search(/(_\w+)+/) != 0) {
	//		    throw("bad atom\n");
	//		}
				return 0;
			} else if (pos < 2) {
				throw("bad atom.");
			}

			this.type = this.buffer.substr(0, pos);
			this.buffer = this.buffer.slice(pos+1);
		}

		if (this.length == -1) {
			var pos = this.buffer.indexOf(" ");

			if (pos == -1) {
				return 0;
			} else if (pos == 0) {
				throw("bad atom.");
			}

			this.length = parseInt(this.buffer.substr(0, pos));
			if (this.length < 0 || this.length.toString() != this.buffer.substr(0, pos)) {
				throw("bad length in atom.\n");
			}
			this.buffer = this.buffer.slice(pos+1);
		}

		if (this.length > this.buffer.length) {
			// add a sanity check. we do not want superlarge data strings, i guess
			return 0;
		}

		var a;

		if (this.length == this.buffer.length) {
			a = new serialization.Atom(this.type, this.buffer);
			this.buffer = "";
		} else {
			a = new serialization.Atom(this.type, this.buffer.substr(0,this.length));
			this.buffer = this.buffer.slice(this.length);
		}
		this.reset();
		
		return a;
    }
});
serialization.Base = Base.extend({
	can_decode : function(atom) {
		return atom.type == this.type; // TODO: inheritance
	},
	toString : function() {
		return "serialization.Base("+this.type+")";
	}
});
serialization.Polymorphic = serialization.Base.extend({
	constructor: function() {
		this.atype_to_type = new Mapping(); // this could use inheritance
		this.ptype_to_type = new Mapping();
	},
	can_decode : function(atom) {
			return this.atype_to_type.hasIndex(atom.type);	
	},
	toString : function() {
		return "Polymorphic()";
	},
	can_encode : function(o) {
		var t = typeof(o);
		if (t == "object") {
			return this.ptype_to_type.hasIndex(o.constructor);
		}
		return this.ptype_to_type.hasIndex(t);
	},
	decode : function(atom) {
		var types = this.atype_to_type.get(atom.type);
		for (var i = 0; i < types.length; i++) {

			if (types[i].can_decode(atom)) {
				return types[i].decode(atom);
			}
		}

		throw("Cannot decode "+atom.toString());
	},
	encode : function(o) {
		var t = typeof(o);
		if (t == "object") t = o.constructor;
		var types = this.ptype_to_type.get(t);

		for (var i = 0; i < types.length; i ++) {
			if (types[i].can_encode(o)) {
				return types[i].encode(o);
			}
		}

		throw("Cannot encode ("+t+","+o.toString()+")");
	},
	register_type : function(atype, ptype, o) {
		var t;

		if (t = this.atype_to_type.get(atype)) {
			t.push(o);
		} else {
			this.atype_to_type.set(atype, new Array(o));
		}

		if (t = this.ptype_to_type.get(ptype)) {
			t.push(o);
		} else {
			this.ptype_to_type.set(ptype, new Array(o));
		}
	}
});
serialization.Date = serialization.Base.extend({
	constructor: function() { 
		this.type = "_time";
	},
	can_encode : function(o) {
		return o instanceof mmp.Date;
	},
	decode : function(atom) {
		return new mmp.Date(parseInt(atom.data));
	},
	encode : function(o) {
		return new serialization.Atom("_time", o.toInt().toString());
	}
});
serialization.Message = serialization.Base.extend({
	constructor : function(method, vars, data) {
		this.mtype = method;
		this.vtype = vars;
		this.dtype = data;
		this.type = "_message";
	},
	can_encode : function(o) {
		return o instanceof yakity.Message;
	},
	decode : function(atom) {
		var p = new serialization.AtomParser();
		var l = p.parse(atom.data);
		var method;
		var data;
		var vars;

		if (l.length == 3 && this.vtype.can_decode(l[0]) && this.dtype.can_decode(l[2]) && this.mtype.can_decode(l[1])) {
			vars = this.vtype.decode(l[0]);		
			data = this.dtype.decode(l[2]);
			method = this.mtype.decode(l[1]);
		} else if (l.length == 2) {
			if (l[0].type.substr(0, 7) == "_method") { // its teh vars
				if (!this.mtype.can_decode(l[0])) throw(this.mtype + " cannot decode " + l[0]);
				if (!this.dtype.can_decode(l[1])) throw(this.dtype + " cannot decode " + l[1]);
				method = this.mtype.decode(l[0]);
				data = this.dtype.decode(l[1]);	
			} else {
				if (!this.vtype.can_decode(l[0])) throw(this.vtype + " cannot decode " + l[0]);
				if (!this.mtype.can_decode(l[1])) throw(this.mtype + " cannot decode " + l[1]);
				vars = this.vtype.decode(l[0]);	
				method = this.mtype.decode(l[1]);
				data = 0;
			}
		} else if (l.length == 1) {
			if (!this.mtype.can_decode(l[0])) throw(this.mtype + " cannot decode " + l[0]);
			method = this.mtype.decode(l[0]);
			data = 0;
		} else throw("bad _message "+l); 

		return new yakity.Message(method, data, vars);
	},
	encode : function(o) {
		var str = "";
		str += this.vtype.encode(o.vars).render();		

		str += this.mtype.encode(o.method).render();

		if (o.data != undefined) {
			str += this.dtype.encode(o.data).render();
		}

		return new serialization.Atom("_message", str);
	}
});
serialization.String = serialization.Base.extend({
	constructor : function() { 
		this.type = "_string";
	},
	can_encode : function(o) {
		return typeof(o) == "string";
	},
	decode : function(atom) {
		return UTF8.decode(atom.data);
	},
	encode : function(o) {
		return new serialization.Atom("_string", UTF8.encode(o));
	}
});
serialization.Integer = serialization.Base.extend({
	constructor : function() { 
		this.type = "_integer";
	},
	can_encode : function(o) {
		return intp(o);
	},
	decode : function(atom) {
		return parseInt(atom.data);
	},
	encode : function(o) {
		return new serialization.Atom("_integer", o.toString());
	}
});
serialization.Float = serialization.Base.extend({
	constructor : function() { 
		this.type = "_float";
	},
	can_encode : function(o) {
		return floatp(o);
	},
	decode : function(atom) {
		return parseFloat(atom.data);
	},
	encode : function(o) {
		return new serialization.Atom("_float", o.toString());
	}
});
serialization.Method = serialization.Base.extend({
	constructor : function(base) { 
		this.base = base;
		this.type = "_method";
	},
	can_encode : function(o) {
		return stringp(o);
	},
	decode : function(atom) {
		return atom.data;
	},
	encode : function(o) {
		return new serialization.Atom("_method", o);
	}
});
serialization.Uniform = serialization.Base.extend({
	constructor : function() { 
		this.type = "_uniform";
	},
	can_encode : function(o) {
		return o instanceof mmp.Uniform;
	},
	decode : function(atom) {
		return mmp.get_uniform(atom.data);
	},
	encode : function(o) {
		return new serialization.Atom("_uniform", o.uniform);
	}
});
serialization.Mapping = serialization.Base.extend({
	constructor : function(mtype, vtype) { 
		this.mtype = mtype;
		this.vtype = vtype;
		this.type = "_mapping";
	},
	toString : function() {
		return "Mapping()";
	},
	can_encode : function(o) {
		return o instanceof Mapping;
	},
	can_decode : function(atom) {
		if (!this.base(atom)) return false;

		var p = new serialization.AtomParser();
		var l = p.parse(atom.data);

		if (l.length & 1) return false;

		for (var i = 0;i < l.length; i+=2) {
			if (!this.mtype.can_decode(l[i])) return false;
			if (!this.vtype.can_decode(l[i+1])) return false;
		}

		return true;
	},
	decode : function(atom) {
		var p = new serialization.AtomParser();
		var l = p.parse(atom.data);
		var m = this.constr ? new this.constr() : new Mapping();

		if (l.length & 1) throw("Malformed mapping.\n");
		
		for (var i = 0;i < l.length; i+=2) {
			var key = this.mtype.decode(l[i]);
			var val = this.vtype.decode(l[i+1]);
			m.set(key, val);
		}

		return m;
	},
	encode : function(o) {
		var str = "";

		o.forEach(function (key, val) {
			if (!this.mtype.can_encode(key) || !this.vtype.can_encode(val)) {
				throw("Type cannot encode "+key+"("+this.mtype.can_encode(key)+") : "+val+"("+this.vtype.can_encode(val)+")");
			}

			str += this.mtype.encode(key).render();	
			str += this.vtype.encode(val).render();	
		}, this);
		return new serialization.Atom("_mapping", str);
	},
});
serialization.OneTypedVars = serialization.Base.extend({
	constructor : function(type) { 
		this.vtype = type;
		this.type = "_vars";
	},
	toString : function() {
		return "Vars("+this.vtype+")";
	},
	can_encode : function(o) {
		var name;

		for (name in o) if (o.hasOwnProperty(name)) {
			if (!this.vtype.can_encode(o[name])) {
				return false;
			}
		}

		return true;
	},
	encode : function(o) {
		var l = [];
		var name;
		var type = this.vtype;

		for (name in o) if (o.hasOwnProperty(name)) {
			if (type.can_encode(o[name])) {
				l.push("_method "+name.length+" "+name);
				l.push(type.encode(o[name]).render());
			}
		}

		return new serialization.Atom("_vars", l.join(""));
	},
	decode : function(atom) {
		var p = new serialization.AtomParser();
		var l = p.parse(atom.data);
		var type = this.vtype;
		var i, name, vars = {};

		if (l.length & 1) throw(atom+" has odd number of entries.");

		for (i = 0; i < l.length; i+=2) {
			if (l[i].type === "_method") {
				name = l[i].data;

				if (!type.can_decode(l[i+1])) {
					throw("Cannot decode entry "+name);
				}

				vars[name] = type.decode(l[i+1]);
			}
		}

		return vars;
	}
});
serialization.Vars = serialization.Base.extend({
	constructor : function(types) { 
		this.types = types;
		this.type = "_vars";
	},
	toString : function() {
		return "Vars()";
	},
	can_encode : function(o) {
		return o instanceof mmp.Vars;
	},
	encode : function(o) {
		var l = [];
		var name;

		for (name in this.types) if (this.types.hasOwnProperty(name) && o.hasIndex(name)) {
			if (this.types[name].can_encode(o.get(name))) {
				l.push("_method "+name.length+" "+name);
				l.push(this.types[name].encode(o.get(name)).render());
			}
		}

		return new serialization.Atom("_vars", l.join(""));
	},
	decode : function(atom) {
		var p = new serialization.AtomParser();
		var l = p.parse(atom.data);
		var i, name, vars = new mmp.Vars();

		if (l.length & 1) throw(atom+" has odd number of entries.");

		for (i = 0; i < l.length; i+=2) {
			if (l[i].type === "_method") {
				name = l[i].data;

				if (!this.types.hasOwnProperty(name)) {
					throw("Cannot decode entry "+name);
				}

				vars.set(name, this.types[name].decode(l[i+1]));
			}
		}

		return vars;
	}
});
serialization.Struct = serialization.Base.extend({
	constructor : function() {
		this.types = Array.prototype.slice.call(arguments);
		if (meteor.debug) meteor.debug("arguments "+arguments);
		if (meteor.debug) meteor.debug("types "+this.types);
	},
	decode : function(atom) {
		var p = new serialization.AtomParser();
		var l = p.parse(atom.data);

		if (l.length != this.types.length) throw(this+": "+atom+" contains "+l.length+" (need "+this.types.length+")");
		
		for (var i = 0; i < l.length; i++) {
			if (this.types[i].can_decode(l[i])) {
				l[i] = this.types[i].decode(l[i]);
			} else {
				throw(this+": cannot decode "+atom+" at position "+i);
			}
		}

		return l;
	},
	toString : function() {
		var l = this.types.concat();
		for (var i = 0; i < l.length; i++) l[i] = l[i].toString();

		return "Struct("+l.join(", ")+")";
	},
	encode : function(l) {
		var d = "";

		if (l.length != this.types.length) throw("Cannot encode atom "+atom.toString());

		for (var i = 0; i < l.length; i++) {
			d += this.types[i].encode(l[i]).render();
		}

		return new serialization.Atom(this.type, d);
	}
});
serialization.Packet = serialization.Struct.extend({
	constructor : function(dtype) {
		this.type = "_mmp";
		var uniform = new serialization.Uniform();
		var integer = new serialization.Integer();
		this.base(dtype, new serialization.Vars({ 
			_timestamp : new serialization.Date(),
			_source : uniform, 
			_target : uniform, 
			_context : uniform, 
			_id : integer, 
			_source_relay : uniform 
		}));
	},
	can_encode : function(o) {
		return o instanceof mmp.Packet;
	},
	encode : function(o) {
		return this.base([ o.data, o.vars ]);
	},
	decode : function(atom) {
		var l = this.base(atom);
		return new mmp.Packet(l[0], l[1]);
	}
});
serialization.Or = serialization.Base.extend({
	constructor : function() {
		this.types = arguments;
	},
	toString : function() {
		var l = this.types.concat();
		for (var i = 0; i < l.length; i++) l[i] = l[i].toString();

		return "Or("+l.join(", ")+")";
	},
	can_encode : function(o) {
		for (var i = 0; i < this.types.length; i++) {
			if (this.types[i].can_encode(o)) return true;
		}
		return false;
	},
	can_decode : function(atom) {
		for (var i = 0; i < this.types.length; i++) {
			if (this.types[i].can_decode(atom)) return true;
		}
		return false;
	},
	decode : function(atom) {
		for (var i = 0; i < this.types.length; i++) {
			if (this.types[i].can_decode(atom)) {
				return this.types[i].decode(atom);
			}
		}

		throw("No type in "+this+" to decode "+atom);
	},
	encode : function(o) {
		for (var i = 0; i < this.types.length; i++) {
			if (this.types[i].can_encode(o)) {
				return this.types[i].encode(o);
			}
		}

		throw("No type in "+this+" to encode "+o);
	}
});
serialization.Array = serialization.Base.extend({
	constructor : function(type) { 
		this.type = "_list";
		this.etype = type;
	},
	can_encode : function(o) {
		return o instanceof Array;
	},
	decode : function(atom) {
		var p = new serialization.AtomParser();
		var l = p.parse(atom.data);
		for (var i = 0; i < l.length; i++) l[i] = this.etype.decode(l[i]);
		return l;
	},
	encode : function(o) {
		var str = "";
		for (var i = 0; i < o.length; i++) {
			str += this.etype.encode(o[i]).render();
		}
		return new serialization.Atom("_list", str);
	}
});
