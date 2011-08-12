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
serialization.parse_atom = function(s) {
    var atom;
    var p = new serialization.AtomParser();
    p.feed(s);
    atom = p._parse();
    return atom;
};
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
	feed : function(data) {
		this.buffer += data;
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
	//		    UTIL.error("bad atom\n");
	//		}
				return 0;
			} else if (pos < 2) {
				UTIL.error("bad atom.");
			}

			this.type = this.buffer.substr(0, pos);
			this.buffer = this.buffer.slice(pos+1);
		}

		if (this.length == -1) {
			var pos = this.buffer.indexOf(" ");

			if (pos == -1) {
				return 0;
			} else if (pos == 0) {
				UTIL.error("bad atom.");
			}

			this.length = parseInt(this.buffer.substr(0, pos));
			if (this.length < 0 || this.length.toString() != this.buffer.substr(0, pos)) {
				UTIL.error("bad length in atom.\n");
			}
			this.buffer = this.buffer.slice(pos+1);
		}

		//UTIL.log("%d vs %d\n", this.length, this.buffer.length);
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
	},
	parse_method : function() {
		var pos = this.buffer.indexOf(" ");
		if (-1 == pos) return 0;
		var method = this.buffer.substr(0, pos);
		this.buffer = this.buffer.slice(pos+1);
		return method;
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
serialization.Any = Base.extend({
	can_decode : function(atom) { return atom instanceof serialization.Atom; },
	can_encode : function(o) { return atom instanceof serialization.Atom; },
	decode : function(atom) { return atom; },
	encode : function(o) { return o; }
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

	UTIL.error("Cannot decode "+atom.toString());
    },
    encode : function(o) {
	var types;
	if (UTIL.objectp(o)) {
	    types = this.ptype_to_type.get(o.constructor);
	}
	if (!types || types.length == 0) {
	    types = this.ptype_to_type.get(typeof(o));
	}

	if (types) for (var i = 0; i < types.length; i ++) {
	    if (types[i].can_encode(o)) {
		return types[i].encode(o);
	    }
	}

	UTIL.log("No type found for %o in %o.\n", t, this.ptype_to_type);
	UTIL.error("Cannot encode (%o, %o)", t, o);
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
	constructor: function(prog) { 
		this.prog = prog||Date;
		this.type = "_time";
	},
	can_encode : function(o) {
		return o instanceof this.prog;
	},
	decode : function(atom) {
		return new this.prog(1000*parseInt(atom.data));
	},
	encode : function(o) {
		return new serialization.Atom("_time", Math.round(o.getTime()/1000).toString());
	}
});
serialization.False = serialization.Base.extend({
	constructor : function() { 
		this.type = "_false";
	},
	can_encode : function(o) {
		return !o;
	},
	decode : function(atom) {
		return false;
	},
	encode : function(o) {
		return new serialization.Atom("_false", "");
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
		return UTIL.intp(o);
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
		return UTIL.floatp(o);
	},
	decode : function(atom) {
		return parseFloat(atom.data);
	},
	encode : function(o) {
		return new serialization.Atom("_float", o.toString());
	}
});
serialization.Binary = serialization.Base.extend({
	constructor : function() { 
		this.type = "_binary";
	},
	can_encode : function(o) {
		return UTIL.stringp(o);
	},
	decode : function(atom) {
		return atom.data;
	},
	encode : function(o) {
		return new serialization.Atom(this.type, o);
	}
});
serialization.Method = serialization.Binary.extend({
	constructor : function(base) {
	    this.base = base;
	    this.type = "_method";
	}
});
serialization.Image = serialization.Binary.extend({
	constructor : function() {
	    this.type = "_image";
	},
	can_encode : function(o) {
	    return o instanceof Image && UTIL.has_prefix(o.src, "data:image/");
	},
	encode : function(o) {
	    var pos = o.src.indexOf(",");
	    if (pos == -1) UTIL.error("broken dataurl.\n");
	    return this.base(UTIL.Base64.decode(o.src.substr(pos+1)));
	},
	decode : function(o) {
	    var data = this.base(o);
	    var img = new Image();
	    img.src = UTIL.image_to_dataurl(data);
	    return img;
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
		//UTIL.log("%o %o\n", this, atom);
		if (!this.base(atom)) return false;

		var p = new serialization.AtomParser();
		var l = p.parse(atom.data);


		if (l.length & 1) return false;

		for (var i = 0;i < l.length; i+=2) {
			if (!this.mtype.can_decode(l[i])) {
			    UTIL.log("%o cannot decode %o\n", this.mtype, l[i]);
			    return false;
			}
			if (!this.vtype.can_decode(l[i+1])) {
			    UTIL.log("%o cannot decode %o\n", this.mtype, l[i]);
			    return false;
			}
		}

		return true;
	},
	decode : function(atom) {
		var p = new serialization.AtomParser();
		var l = p.parse(atom.data);
		var m = this.constr ? new this.constr() : new Mapping();

		if (l.length & 1) UTIL.error("Malformed mapping.\n");
		
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
				UTIL.error("Type cannot encode "+key+"("+this.mtype.can_encode(key)+") : "+val+"("+this.vtype.can_encode(val)+")");
			}

			str += this.mtype.encode(key).render();	
			str += this.vtype.encode(val).render();	
		}, this);
		return new serialization.Atom(this.type, str);
	}
});
serialization.Object = serialization.Mapping.extend({
	constructor : function(vtype) { 
		this.base(new serialization.Or(new serialization.Integer(), new serialization.String()),
			  vtype);
		this.type = "_mapping";
	},
	toString : function() {
		return "Object()";
	},
	can_encode : function(o) {
		return UTIL.objectp(o);
	},
	decode : function(atom) {
		var p = new serialization.AtomParser();
		var l = p.parse(atom.data);
		var m = {};

		if (l.length & 1) UTIL.error("Malformed mapping.\n");
		
		for (var i = 0;i < l.length; i+=2) {
			var key = this.mtype.decode(l[i]);
			var val = this.vtype.decode(l[i+1]);
			m[key] = val;
		}

		return m;
	},
	encode : function(o) {
		var str = "";

		for (var key in o) if (o.hasOwnProperty(key)) {
			var val = o[key];
			if (!this.mtype.can_encode(key) || !this.vtype.can_encode(val)) {
			    //UTIL.log("o: %o", o);
				UTIL.error("Type"+key+" cannot encode "+key+"("+this.mtype.can_encode(key)+") : "+val+"("+this.vtype.can_encode(val)+")");
			}

			str += this.mtype.encode(key).render();	
			str += this.vtype.encode(val).render();	
		}
		return new serialization.Atom(this.type, str);
	}
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
		return o instanceof mmp.Vars;
	},
	encode : function(o) {
		var l = [];
		var type = this.vtype;

		o.forEach(function(name, value) {
		    l.push("_method "+name.length+" "+name);
		    l.push(type.encode(value).render());
		});

		return new serialization.Atom("_vars", l.join(""));
	},
	decode : function(atom) {
		var p = new serialization.AtomParser();
		var l = p.parse(atom.data);
		var type = this.vtype;
		var vars = new mmp.Vars();

		if (l.length & 1) UTIL.error(atom+" has odd number of entries.");

		for (var i = 0; i < l.length; i+=2) {
			if (l[i].type === "_method") {
				vars.set(l[i].data, type.decode(l[i+1]));
			} else UTIL.error("Bad key type in _vars: " + l[i].type);
		}

		return vars;
	}
});
serialization.Vars = serialization.Base.extend({
	constructor : function(types) { 
		this.types = new mmp.Vars(types);
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

		o.forEach(function(key, value) {
			if (!mmp.methodp(key)) UTIL.error("The _vars type only allows method keys (got "+key+")");
			var t = this.types.get(key);
			if (!t) UTIL.error("Cannot encode entry "+key);
			l.push(key+" "+t.encode(value).render());
		}, this);

		return new serialization.Atom("_vars", l.join(""));
	},
	decode : function(atom) {
		var p = new serialization.AtomParser();
		p.feed(atom.data);
		var i, name, vars = new mmp.Vars();

		while (p.buffer.length) {
		    var key = p.parse_method();
		    var atom = p._parse();

		    if (!key || !atom) UTIL.error("Malformed _vars Atom: "+p.buffer);
		    if (!mmp.methodp(key)) UTIL.error("Malformed method in _vars: "+key);
		    var t = this.types.get(key);
		    if (!t) UTIL.error("Cannot decode entry "+key);

		    vars.set(key, t.decode(atom));
		}

		return vars;
	}
});
serialization.Tuple = serialization.Base.extend({
	constructor : function(type, p) {
		this.types = Array.prototype.slice.call(arguments, 2);
		//UTIL.log("arguments "+arguments);
		//UTIL.log("types "+this.types);
		this.type = type||"_tuple";
		this.p = p;
	},
	decode : function(atom) {
		var p = new serialization.AtomParser();
		var l = p.parse(atom.data);

		//UTIL.log("list: %o. atom: %o (%s)\n", l, atom, atom.data);

		if (l.length != this.types.length) UTIL.error(this+": '"+atom+"' contains "+l.length+" (need "+this.types.length+")");
		
		for (var i = 0; i < l.length; i++) {
			if (this.types[i].can_decode(l[i])) {
				l[i] = this.types[i].decode(l[i]);
			} else {
				//UTIL.log("%o cannot decode %o\n", this.types[i], l[i]);
				UTIL.error("%o: cannot decode %o at position %d", this, atom, i);
			}
		}

		return this.p ? UTIL.create(this.p, l) : l;
	},
	toString : function() {
		var l = this.types.concat();
		for (var i = 0; i < l.length; i++) l[i] = l[i].toString();

		return "Tuple("+l.join(", ")+")";
	},
	can_encode : function(l) {
		if (this.p)
		    return l instanceof this.p;
		else
		    return UTIL.arrayp(l) && l.length == this.types.length;
	},
	encode : function(l) {
		var d = "";

		if (l.length != this.types.length) UTIL.error("Cannot encode %o (wrong length) %o", l, this.types);

		for (var i = 0; i < l.length; i++) {
			//UTIL.log("encode(%o)", i);
			d += this.types[i].encode(l[i]).render();
		}

		return new serialization.Atom(this.type, d);
	}
});
serialization.Struct = serialization.Tuple.extend({
	constructor : function(type, m, constr) {
		this.names = UTIL.keys(m);
		this.names = this.names.sort();
		this.constr = constr;
		//UTIL.log(this.names);
		var types = [];
		for (var i = 0; i < this.names.length; i++) {
		    //UTIL.log("pushing type %o\n", m[this.names[i]]);
		    types.push(m[this.names[i]]);
		}
		this.base.apply(this, [type||"_struct", false ].concat(types));
	},
	decode : function(atom) {
		var l = this.base(atom);
		var ret = this.constr ? (new this.constr()) : {};

		for (var i = 0; i < this.names.length; i++)
		    ret[this.names[i]] = l[i];

		if (UTIL.functionp(ret.atom_init)) ret.atom_init();
		return ret;
	},
	toString : function() {
		var l = this.types.concat();
		for (var i = 0; i < l.length; i++) l[i] = l[i].toString();

		return "Struct("+l.join(", ")+")";
	},
	can_encode : function(o) {
		return UTIL.objectp(o) && (!this.constr || o instanceof this.constr);
	},
	encode : function(o) {
		var l = [];
		for (var i = 0; i < this.names.length; i ++) {
		    // maybe call if functionp()
		    if (o.hasOwnProperty(this.names[i])) {
			l.push(o[this.names[i]]);
		    } else if (UTIL.functionp(o[this.names[i]])) {
			l.push(o[this.names[i]]());
		    } else UTIL.error("Data is missing entry "+this.names[i]);
		}
		return this.base(l);
	}
});
serialization.generate_structs = function(m) {
    var p = new serialization.Polymorphic();

    for (var atype in m) if (m.hasOwnProperty(atype)) {
	var t = m[atype];
	var types;
	if (t.prototype._types) {
	    types = UTIL.copy(t.prototype._types);
	    for (var n in types) if (types.hasOwnProperty(n)) {
		if (UTIL.functionp(types[n]))
		    types[n] = types[n](p);
	    }
	} else types = {};
	p.register_type(atype, t,
			new serialization.Struct(atype, types, t));
    }

    return p;
}
serialization.Packet = serialization.Tuple.extend({
	constructor : function(dtype) {
		var uniform = new serialization.Uniform();
		var integer = new serialization.Integer();
		this.base("_mmp", false, dtype, new serialization.Vars({ 
			_timestamp : new serialization.Date(mmp.Date),
			_source : uniform, 
			_target : uniform, 
			_context : uniform, 
			_id : integer, 
			_ack : integer, 
			_sequence_max : integer, 
			_sequence_pos : integer, 
			_source_relay : uniform,
			_tag : new serialization.String()
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
		this.types = Array.prototype.slice.apply(arguments);
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

		UTIL.error("No type in "+this+" to decode "+atom);
	},
	encode : function(o) {
		for (var i = 0; i < this.types.length; i++) {
			if (this.types[i].can_encode(o)) {
				return this.types[i].encode(o);
			}
		}

		//UTIL.log("Or(%o)", this.types);
		UTIL.trace();
		UTIL.error("No type in "+this+" to encode "+o);
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
		return new serialization.Atom(this.type, str);
	}
});
serialization.SimpleSet = serialization.Array.extend({
	constructor : function() {
	    this.base(new serialization.Or(
					   new serialization.Integer(),
					   new serialization.String()))
	},
	can_encode : function(o) {
	    return UTIL.objectp(o);
	},
	encode : function(o) {
	    return this.base(UTIL.keys(o)); 
	},
	decode : function(atom) {
	    var l = this.base(atom);
	    var o = {};
	    for (var i = 0; i < l.length; i++)
		o[l[i]] = 1;
	    return o;
	}
});
