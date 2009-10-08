serialization = new Object();
serialization.Base = function() {};
serialization.Base.prototype = {
	can_decode : function(atom) {
		return atom.type == this.type; // TODO: inheritance
	},
	toString : function() {
		return "serialization.Base("+this.type+")";
	}
};
serialization.Polymorphic = function() {
	this.atype_to_type = new Mapping(); // this could use inheritance
	this.ptype_to_type = new Mapping();
};
serialization.Polymorphic.prototype = new serialization.Base();
serialization.Polymorphic.prototype.can_decode = function(atom) {
		return this.atype_to_type.hasIndex(atom.type);	
};
serialization.Polymorphic.prototype.toString = function() {
	return "Polymorphic()";
},
serialization.Polymorphic.prototype.can_encode = function(o) {
	var t = typeof(o);
	if (t == "object") {
		return this.ptype_to_type.hasIndex(o.constructor);
	}
	return this.ptype_to_type.hasIndex(t);
};
serialization.Polymorphic.prototype.decode = function(atom) {
	var types = this.atype_to_type.get(atom.type);
	for (var i = 0; i < types.length; i++) {
		if (types[i].can_decode(atom)) {
			return types[i].decode(atom);
		}
	}

	throw("Cannot decode "+atom.toString());
};
serialization.Polymorphic.prototype.encode = function(o) {
	var t = typeof(o);
	if (t == "object") t = o.constructor;
	var types = this.ptype_to_type.get(t);

	for (var i = 0; i < types.length; i ++) {
		if (types[i].can_encode(o)) {
			return types[i].encode(o);
		}
	}

	throw("Cannot encode ("+t+","+o.toString()+")");
};
serialization.Polymorphic.prototype.register_type = function(atype, ptype, o) {
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
};
serialization.Polymorphic.prototype.constructor = serialization.Polymorphic;
serialization.Date = function() { 
	this.type = "_time";
};
serialization.Date.prototype = new serialization.Base();
serialization.Date.prototype.can_encode = function(o) {
	return o instanceof psyc.Date;
};
serialization.Date.prototype.decode = function(atom) {
	return new psyc.Date(parseInt(atom.data));
};
serialization.Date.prototype.encode = function(o) {
	return new psyc.Atom("_time", o.timestamp);
};
serialization.Date.prototype.constructor = serialization.Date;
serialization.Message = function(method, vars, data) {
	this.mtype = method;
	this.vtype = vars;
	this.dtype = data;
	this.type = "_message";
},
serialization.Message.prototype = new serialization.Base();
serialization.Message.prototype.can_encode = function(o) {
	return o instanceof psyc.Message;
};
serialization.Message.prototype.decode = function(atom) {
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
};
serialization.Message.prototype.encode = function(o) {
	var str = "";
	str += this.vtype.encode(o.vars).render();		

	str += this.mtype.encode(o.method).render();

	if (o.data != undefined) {
		str += this.dtype.encode(o.data).render();
	}

	return new psyc.Atom("_message", str);
};
serialization.Message.prototype.constructor = serialization.Message;
serialization.String = function() { 
	this.type = "_string";
};
serialization.String.prototype = new serialization.Base();
serialization.String.prototype.can_encode = function(o) {
	return typeof(o) == "string";
};
serialization.String.prototype.decode = function(atom) {
	return UTF8.decode(atom.data);
};
serialization.String.prototype.encode = function(o) {
	return new psyc.Atom("_string", UTF8.encode(o));
};
serialization.String.prototype.constructor = serialization.String;
serialization.Integer = function() { 
	this.type = "_integer";
};
serialization.Integer.prototype = new serialization.Base();
serialization.Integer.prototype.can_encode = function(o) {
	return intp(o);
};
serialization.Integer.prototype.decode = function(atom) {
	return parseInt(atom.data);
};
serialization.Integer.prototype.encode = function(o) {
	return new psyc.Atom("_integer", o.toString());
};
serialization.Integer.prototype.constructor = serialization.Integer;
serialization.Float = function() { 
	this.type = "_float";
};
serialization.Float.prototype = new serialization.Base();
serialization.Float.prototype.can_encode = function(o) {
	return floatp(o);
};
serialization.Float.prototype.decode = function(atom) {
	return parseFloat(atom.data);
};
serialization.Float.prototype.encode = function(o) {
	return new psyc.Atom("_float", o.toString());
};
serialization.Float.prototype.constructor = serialization.Float;
serialization.Method = function(base) { 
	this.base = base;
	this.type = "_method";
};
serialization.Method.prototype = new serialization.Base();
serialization.Method.prototype.can_encode = function(o) {
	return stringp(o);
};
serialization.Method.prototype.decode = function(atom) {
	return atom.data;
};
serialization.Method.prototype.encode = function(o) {
	return new psyc.Atom("_method", o);
};
serialization.Method.prototype.constructor = serialization.Method;
serialization.Uniform = function() { 
	this.type = "_uniform";
};
serialization.Uniform.prototype = new serialization.Base();
serialization.Uniform.prototype.can_encode = function(o) {
	return o instanceof psyc.Uniform;
};
serialization.Uniform.prototype.decode = function(atom) {
	return psyc.get_uniform(atom.data);
};
serialization.Uniform.prototype.encode = function(o) {
	return new psyc.Atom("_uniform", o.uniform);
};
serialization.Uniform.prototype.constructor = serialization.Uniform;
serialization.Mapping = function(mtype, vtype) { 
	this.mtype = mtype;
	this.vtype = vtype;
	this.type = "_mapping";
};
serialization.Mapping.prototype = new serialization.Base();
serialization.Mapping.prototype.can_encode = function(o) {
	return o instanceof psyc.Mapping;
};
serialization.Mapping.prototype.decode = function(atom) {
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
};
serialization.Mapping.prototype.encode = function(o) {
	var str = "";

	o.forEach(function (key, val) {
		if (!this.mtype.can_encode(key) || !this.vtype.can_encode(val)) {
			throw("Type cannot encode "+key+"("+this.mtype.can_encode(key)+") : "+val+"("+this.vtype.can_encode(val)+")");
		}

		str += this.mtype.encode(key).render();	
		str += this.vtype.encode(val).render();	
	}, this);
	return new psyc.Atom("_mapping", str);
};
serialization.Mapping.prototype.constructor = serialization.Mapping;
serialization.Vars = function(vtype) { 
	this.mtype = new serialization.Method();
	this.vtype = vtype;
	this.constr = psyc.Vars;
	this.type = "_mapping";
	this.can_encode = function(o) {
		return o instanceof psyc.Vars;
	};
};
serialization.Vars.prototype = new serialization.Mapping();
serialization.Vars.prototype.constructor = serialization.Vars;
serialization.Array = function(type) { 
	this.type = "_list";
	this.etype = type;
};
serialization.Array.prototype = new serialization.Base();
serialization.Array.prototype.can_encode = function(o) {
	return o instanceof Array;
};
serialization.Array.prototype.decode = function(atom) {
	var p = new psyc.AtomParser();
	var l = p.parse(atom.data);
	var i = 0;
	while (i < l.length) {
		l[i] = this.etype.decode(l[i]);
		i++;
	}

	return l;
};
serialization.Array.prototype.encode = function(o) {
	var str = "";
	for (var i = 0; i < o.length; i++) {
		str += this.etype.encode(o[i]).render();
	}
	return new psyc.Atom("_list", str);
};
serialization.Array.prototype.constructor = serialization.Array;
