serialization = new Object();
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
		return o instanceof psyc.Date;
	},
	decode : function(atom) {
		return new psyc.Date(parseInt(atom.data));
	},
	encode : function(o) {
		return new psyc.Atom("_time", o.timestamp);
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
		return o instanceof psyc.Message;
	},
	decode : function(atom) {
		var p = new psyc.AtomParser();
		var l = p.parse(atom.data);
		var method;
		var data;
		var vars;

		if (l.length == 3) {
			vars = this.vtype.decode(l[0]);		
			data = this.dtype.decode(l[2]);
			method = this.mtype.decode(l[1]);
		} else if (l.length == 2) {
			if (l[0].type.substr(0, 7) == "_method") { // its teh vars
				method = this.mtype.decode(l[0]);
				data = this.dtype.decode(l[1]);	
			} else {
				vars = this.vtype.decode(l[0]);		
				method = this.mtype.decode(l[1]);
				data = 0;
			}
		} else if (l.length != 1) {
			throw("bad _message"); 
		}

		return new psyc.Message(method, vars, data);
	},
	encode : function(o) {
		var str = "";
		str += this.vtype.encode(o.vars).render();		

		str += this.mtype.encode(o.method).render();

		if (o.data != undefined) {
			str += this.dtype.encode(o.data).render();
		}

		return new psyc.Atom("_message", str);
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
		return new psyc.Atom("_string", UTF8.encode(o));
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
		return new psyc.Atom("_integer", o.toString());
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
		return new psyc.Atom("_float", o.toString());
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
		return new psyc.Atom("_method", o);
	}
});
serialization.Uniform = serialization.Base.extend({
	constructor : function() { 
		this.type = "_uniform";
	},
	can_encode : function(o) {
		return o instanceof psyc.Uniform;
	},
	decode : function(atom) {
		return psyc.get_uniform(atom.data);
	},
	encode : function(o) {
		return new psyc.Atom("_uniform", o.uniform);
	}
});
serialization.Mapping = serialization.Base.extend({
	constructor : function(mtype, vtype) { 
		this.mtype = mtype;
		this.vtype = vtype;
		this.type = "_mapping";
	},
	can_encode : function(o) {
		return o instanceof psyc.Mapping;
	},
	decode : function(atom) {
		var p = new psyc.AtomParser();
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
		return new psyc.Atom("_mapping", str);
	},
});
serialization.Vars = serialization.Mapping.extend({
	constructor : function(vtype) { 
		this.mtype = new serialization.Method();
		this.vtype = vtype;
		this.constr = psyc.Vars;
		this.type = "_mapping";
	},
	can_encode : function(o) {
		return o instanceof psyc.Vars;
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
		var p = new psyc.AtomParser();
		var l = p.parse(atom.data);
		var i = 0;
		while (i < l.length) {
			l[i] = this.etype.decode(l[i]);
			i++;
		}

		return l;
	},
	encode : function(o) {
		var str = "";
		for (var i = 0; i < o.length; i++) {
			str += this.etype.encode(o[i]).render();
		}
		return new psyc.Atom("_list", str);
	}
});
