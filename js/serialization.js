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
serialization.lambda = {
};
/**
 * Atom class.
 * @constructor
 * @param {String} type Atom type, e.g. _integer
 * @param {String} data String representation of the value
 * @property {String} type Atom type, e.g. _integer.
 * @property {String} data String representation of the value
 */
serialization.Atom = function(type, data) {
    this.type = type;
    this.data = data;
};
serialization.Atom.prototype = {
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
};
serialization.parse_atom = function(s) {
    var atom;
    var p = new serialization.AtomParser();
    p.feed(s);
    atom = p._parse();
    return atom;
};
serialization.low_parse_atoms = function(s) {
    var ret = [];
    var i = 0;    
    //var re = /(\w+) (\d+) /g;
    var re = new RegExp("(\\w+) (\\d+) ", "g");
    var r, length;

    // BUG: this line is needed since firefox seems to be too good
    // at optimizing
    //re.lastIndex = 0;

    while (i < s.length) {
	r = re.exec(s);
	if (!r) {
	    window.s = s;
	    UTIL.error("Bad atom!");
	}
	i = re.lastIndex;
	length = parseInt(r[2]);

	ret.push(r[1]);
	ret.push(s.substr(i, length));

	i += length;
	re.lastIndex = i;
    }

    return ret;
};
serialization.parse_atoms = function(s) {
    var ret = serialization.low_parse_atoms(s);
    var r = new Array(ret.length/2);
    for (var i = 0; i < ret.length; i+=2) {
	r[i/2] = new serialization.Atom(ret[i], ret[i+1]);
    }
    return r;
};
/**
 * Atom parser class.
 * @constructor
 */
serialization.AtomParser = Base.extend({
    constructor : function() {
	this.buffer = "";
	this.offset = 0;
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
	if (UTIL.stringp(str))
	    this.buffer += str;

	var ret = [];
	var t = 0;
	while (t = this._parse()) {
	    ret.push(t);
	}
	return ret;
    },
    /*
     // this is an alternative to the other _parse using RegExp.
     // It performs as well as the one using indexOf.
    _parse : function() {
	var re = this.re, a;

	if (!this.type) {
	    var pos = re.lastIndex;
	    var r = re.exec(this.buffer);
	    if (!r) {
		// TODO we somehow need to detect bad content here
		re.lastIndex = pos;
		return null;
	    }
	    this.type = r[1];
	    this.length = parseInt(r[2]);
	}

	if (this.buffer.length >= this.length + re.lastIndex) {
	    a = new serialization.Atom(this.type,
		this.buffer.substr(re.lastIndex, this.length));
	    re.lastIndex += this.length;
	    this.reset();

	    if (re.lastIndex == this.buffer.length) {
		this.buffer = "";
		re.lastIndex = 0;
	    }
	}

	return a;
    },
    */
    _parse : function() {
	var pos;
	if (!this.type) {
	    pos = this.buffer.indexOf(" ", this.offset);

	    if (pos == -1) {
	    // check here for bogus data
//		if (re[0].search(/(_\w+)+/) != 0) {
//		    UTIL.error("bad atom\n");
//		}
		return 0;
	    } else if (pos < 2) {
		UTIL.error("bad atom.");
	    }

	    this.type = this.buffer.substring(this.offset, pos);
	    this.offset = pos+1;
	}

	if (this.length == -1) {
	    pos = this.buffer.indexOf(" ", this.offset);

	    if (pos == -1) {
		return 0;
	    } else if (pos == this.offset) {
		UTIL.error("bad atom.");
	    }

	    this.length = parseInt(this.buffer.substring(this.offset, pos));
	    if (this.length < 0 || this.length.toString() != this.buffer.substring(this.offset, pos)) {
		UTIL.error("bad length in atom.\n");
	    }
	    this.offset = pos+1;
	}

	//UTIL.log("%d vs %d\n", this.length, this.buffer.length);
	if (this.length + this.offset > this.buffer.length) {
	    // add a sanity check. we do not want superlarge data strings, i guess
	    return 0;
	}

	var a;

	if (this.length + this.offset == this.buffer.length) {
	    a = new serialization.Atom(this.type, this.buffer.substr(this.offset));
	    this.buffer = "";
	    this.offset = 0;
	} else {
	    a = new serialization.Atom(this.type, this.buffer.substr(this.offset,this.length));
	    this.offset += this.length;
	}
	this.reset();
	
	return a;
    },
    parse_method : function() {
	var pos = this.buffer.indexOf(" ", this.offset);
	if (-1 == pos) return 0;
	var method = this.buffer.substring(this.offset, pos);
	this.buffer = this.buffer.slice(this.offset+pos+1);
	this.offset = 0;
	return method;
    }
});
serialization.BaseClass = {
    can_decode : function(atom) {
	return atom.type == this.type; // TODO: inheritance
    },
    toString : function() {
	return "serialization.Base("+this.type+")";
    },
    render : function(o) {
	return this.encode(o).render();
    },
    extend : function(m) {
    },
    generate_decode : function(type, data, ret) {
	var c = ret.scope.Extern(UTIL.make_method(this, this.decode));
	return ret.Set(new lambda.Template("%%(new serialization.Atom(%%, %%))",
					    c, type, data));
    },
    generate_can_decode : function(type, data, ret) {
	var c = ret.scope.Extern(UTIL.make_method(this, this.can_decode));
	return ret.Set(new lambda.Template("%%(new serialization.Atom(%%, %%))",
					    c, type, data));
    },
    generate_can_encode : function(o, ret) {
	var c = ret.scope.Extern(UTIL.make_method(this, this.can_encode));
	return ret.Set(new lambda.Template("%%(%%)",
					    c, o));
    },
    generate_encode : function(o, type, data) {
	var b = new lambda.Block(data.scope);
	var c = data.scope.Extern(UTIL.make_method(this, this.encode));
	var t = data.scope.Var();

	b.add(t.Set(new lambda.Template("%%(%%)", c, o)));
	b.add(type.Set(t.Index("type")));
	b.add(data.Set(t.Index("data")));
	return b;
    }
};
serialization.Base = Base.extend(serialization.BaseClass);
serialization.Generated = Base.extend({
    constructor : function() {
	if (!this._decode) {
	    var f = new lambda.Function();
	    var ret = f.Var();
	    f.block.add(this.generate_decode(f.$(1).Index("type"),
					 f.$(1).Index("data"),
					 ret));
	    f.block.add(f.Return(ret));
	    this._decode = f.compile();
	}
	if (!this._can_decode) {
	    var f = new lambda.Function();
	    var ret = f.Var();
	    f.block.add(this.generate_can_decode(f.$(1).Index("type"),
					 f.$(1).Index("data"),
					 ret));
	    f.block.add(f.Return(ret));
	    this._can_decode = f.compile();
	}
	if (!this._encode) {
	    var f = new lambda.Function();
	    var ret = f.Var();
	    var data = f.Var();
	    f.block.add(this.generate_encode(f.$(1), ret, data));
	    f.block.add("%% = new serialization.Atom(%%, %%)", ret, ret, data);
	    f.block.add(f.Return(ret));
	    this._encode = f.compile();
	}
	if (!this._can_encode) {
	    var f = new lambda.Function();
	    var ret = f.Var();
	    f.block.add(this.generate_can_encode(f.$(1), ret));
	    f.block.add(f.Return(ret));
	    this._can_encode = f.compile();
	}

	if (!this._render) {
	    var f = new lambda.Function();
	    var ret = f.Var();
	    var data = f.Var();
	    f.block.add(this.generate_encode(f.$(1), ret, data));
	    f.block.add("%% = %% +\" \"+ %%.length +\" \"+ %%", ret, ret, ret, data);
	    f.block.add(f.Return(ret));
	    this._render = f.compile();
	}
    },
    toString : function() {
	return "serialization.Generated("+this.type+")";
    },
    decode : function(atom) {
	return this._decode(atom);
    },
    can_decode : function(atom) {
	return this._can_decode(atom);
    },
    encode : function(o) {
	return this._encode(o);
    },
    can_encode : function(o) {
	return this._can_encode(o);
    },
    render : function(o) {
	return this._render(o);
    },
    generate_can_decode : function(type, data, ret) {
	return ret.Set(new lambda.Template("%% === %%", type, this.type));
    },
});
serialization.Any = serialization.Generated.extend({
    generate_can_decode : function(type, data, ret) {
	return ret.Set(true);
    },
    generate_can_encode : function(o, ret) {
	return ret.Set(new lambda.Template("%% instanceof serialization.Atom",
					   o));
    },
    generate_decode : function(type, data, ret) {
	return ret.Set(new lambda.Template("new serialization.Atom(%%,%%)",
					   type, data));
    },
    generate_encode : function(o, type, data) {
	var b = new lambda.Block(data.scope);
	b.add(type.Set(o.Index("type")));
	b.add(data.Set(o.Index("data")));
	return b;
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

	if (types) for (var i = 0; i < types.length; i++) {
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
		window.badfun = types[i].encode;
		return types[i].encode(o);
		delete window.badfun;
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
serialization.Date = serialization.Generated.extend({
    constructor: function(prog) { 
	this.prog = prog;
	this.type = "_time";
	this.base();
    },
    generate_can_encode : function(o, ret) {
	if (this.prog) {
	    var c = o.scope.Extern(this.prog);
	    return ret.Set(new lambda.Template("%% instanceof %%", o, c));
	} else return ret.Set(new lambda.Template("%% instanceof Date", o));
    },
    generate_decode : function(type, data, ret) {
	if (this.prog) {
	    var c = ret.scope.Extern(this.prog);
	    return ret.Set(new lambda.Template("(new %%(1000*parseInt(%%)))", c, data));
	} else return ret.Set(new lambda.Template("(new Date(1000*parseInt(%%)))", data));
    },
    generate_encode : function(o, type, data) {
	var b = new lambda.Block(data.scope);
	b.add(type.Set(this.type));
	b.add(data.Set(new lambda.Template("Math.round(%%.getTime()/1000).toString()", o)));
	return b;
				     
    }
});
serialization.Singleton = serialization.Generated.extend({
    constructor : function(type, value) {
	this.type = type;
	this.value = value;
	this.base();
    },
    generate_can_encode : function(o, ret) {
	var c = o.scope.Extern(this.value);
	return ret.Set("%% === %%", o, c);
    },
    generate_decode : function(type, data, ret) {
	return ret.Set(type.scope.Extern(this.value));
    },
    generate_encode : function(o, type, data) {
	var b = new lambda.Block(data.scope);
	b.add(type.Set(this.type));
	b.add(data.Set(""));
	return b;
    }
});
serialization.String = serialization.Generated.extend({
    constructor : function() { 
	this.type = "_string";
	this.base();
    },
    generate_can_encode : function(o, ret) {
	return ret.Set(new lambda.Template("typeof(%%) == %%", o, "string"));
    },
    generate_decode : function(type, data, ret) {
	return ret.Set(new lambda.Template("UTF8.decode(%%)", data));
    },
    generate_encode : function(o, type, data) {
	var b = new lambda.Block(data.scope);
	b.add(type.Set(this.type));
	b.add(data.Set(new lambda.Template("UTF8.encode(%%)", o)));
	return b;
    }
});
serialization.Integer = serialization.Generated.extend({
    constructor : function() { 
	this.type = "_integer";
	this.base();
    },
    generate_can_encode : function(o, ret) {
	return ret.Set(new lambda.Template("%% instanceof \"number\" && %% % 1.0 == 0.0", o, o));
    },
    generate_decode : function(type, data, ret) {
	return ret.Set(new lambda.Template("parseInt(%%)", data));
    },
    generate_encode : function(o, type, data) {
	var b = new lambda.Block(data.scope);
	b.add(type.Set(this.type));
	b.add(data.Set(new lambda.Template("%%.toString()", o)));
	return b;
    }
});
serialization.Float = serialization.Generated.extend({
    constructor : function() { 
	this.type = "_float";
	this.base();
    },
    generate_can_encode : function(o, ret) {
	return ret.Set(new lambda.Template("UTIL.floatp(%%)", o));
    },
    generate_decode : function(type, data, ret) {
	return ret.Set(new lambda.Template("parseFloat(%%)", data));
    },
    generate_encode : function(o, type, data) {
	var b = new lambda.Block(data.scope);
	b.add(type.Set(this.type));
	b.add(data.Set(new lambda.Template("%%.toString()", o)));
	return b;
    }
});
serialization.Binary = serialization.Generated.extend({
    constructor : function() { 
	    this.type = "_binary";
    },
    generate_can_encode : function(o, ret) {
	return ret.Set(new lambda.Template("UTIL.stringp(%%)", o));
    },
    generate_decode : function(type, data, ret) {
	return ret.Set(data);
    },
    generate_encode : function(o, type, data) {
	var b = new lambda.Block(data.scope);
	b.add(type.Set(this.type));
	b.add(data.Set(data));
	return b;
    }
});
serialization.Method = serialization.Binary.extend({
    constructor : function() {
	this.base();
	this.type = "_method";
    }
});
serialization.Image = serialization.Binary.extend({
	constructor : function() {
	    this.type = "_image";
	},
    generate_can_encode : function(o, ret) {
	return ret.Set(new lambda.Template("%% instanceof Image && UTIL.has_prefix(%%.src, \"data:image/\")", o, o));
    },
    generate_decode : function(type, data, ret) {
	var b = new lambda.Block(data.scope);
	b.add(ret.Set(new lambda.Template("new Image()")));
	b.add(ret.Index("src").Set(new lambda.Template("UTIL.image_to_dataurl(%%)", data)));
	return b;
    },
    generate_encode : function(o, type, data) {
	var pos = o.scope.Var();
	var b = new lambda.Block(data.scope);
	b.add(pos.Set(new lambda.Template("%%.src.indexOf(\",\")", o)));
	b.If("%% === -1", pos)
	    .add("UTIL.error(%%)","broken dataurl.\n");
	b.add(o.Set(new lambda.Template("UTIL.Base64.decode(%%.src.substr(%%+1))", o, pos)));
	b.add(this.base(o, type, data));
	return b;
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
	constr : Mapping,
	toString : function() {
		return "Mapping()";
	},
	can_encode : function(o) {
	    return o instanceof this.constr;
	},
	decode : function(atom) {
	    var l = serialization.parse_atoms(atom.data);
	    var m = new this.constr();

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

		o.forEach(UTIL.make_method(this, function (key, val) {
			if (!this.mtype.can_encode(key) || !this.vtype.can_encode(val)) {
				UTIL.error("Type cannot encode "+key+"("+this.mtype.can_encode(key)+") : "+val+"("+this.vtype.can_encode(val)+")");
			}

			str += this.mtype.render(key);
			str += this.vtype.render(val);
		}));
		return new serialization.Atom(this.type, str);
	}
});
serialization.Object = serialization.Mapping.extend({
	constructor : function(vtype) { 
	    this.base(new serialization.String(),
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
	    var l = serialization.parse_atoms(atom.data);
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
	    var ret = UTIL.keys(o);

	    for (var i = 0; i < ret.length; i++) {
		var key = ret[i];
		var val = o[key];
		if (!this.mtype.can_encode(key) || !this.vtype.can_encode(val)) {
		    UTIL.error("Type"+key+" cannot encode "+key+"("+this.mtype.can_encode(key)+") : "+val+"("+this.vtype.can_encode(val)+")");
		}

		ret[i] = this.mtype.encode(key).render()
		       + this.vtype.encode(val).render();	
	    }
	    return new serialization.Atom(this.type, ret.join(""));
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
		    l.push("_method " + name.length + " " + name
			   + type.render(value));
		});

		return new serialization.Atom("_vars", l.join(""));
	},
	decode : function(atom) {
		var l = serialization.parse_atoms(atom.data);
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
serialization.Tuple = serialization.Generated.extend({
    constructor : function(type, p) {
	this.types = Array.prototype.slice.call(arguments, 2);
	//UTIL.log("arguments "+arguments);
	//UTIL.log("types "+this.types);
	this.type = type||"_tuple";
	this.p = p;
	this.base();
    },
    generate_decode : function(type, data, ret) {
	var b = new lambda.Block(data.scope);
	var l = type.scope.Var();
	b.add(l.Set(new lambda.Template("serialization.low_parse_atoms(%%)", data)));
	for (var i = 0; i < this.types.length; i++) {
	    b.add(this.types[i].generate_decode(l.Index(i*2), l.Index(2*i+1), l.Index(i)));
	}
	if (this.p) {
	    var c = type.scope.Extern(this.p);
	    b.add(ret.Set(new lambda.Template("UTIL.create(%%, %%.slice(0, %%))", c, l, this.types.length)));
	} else {
	    b.add(ret.Set(new lambda.Template("%%.slice(0, %%)", l, this.types.length)));
	}

	return b;
    },
    toString : function() {
	var l = this.types.concat();
	for (var i = 0; i < l.length; i++) l[i] = l[i].toString();

	return "Tuple("+l.join(", ")+")";
    },
    generate_can_encode : function(o, ret) {
	if (this.p) {
	    var c = o.scope.Extern(this.p);
	    return ret.Set(new lambda.Template("%% instanceof %%", o, c));
	} else {
	    return ret.Set(new lambda.Template("UTIL.arrayp(%%) && %%.length === %%", o, o, this.types.length));
	}
    },
    generate_encode : function(o, type, data) {
	var b = new lambda.Block(data.scope);
	var l = type.scope.Array(this.types.length*3);

	if (this.p) {
	    b.If("!UTIL.arrayp(%%)", o).add(o.Set(
		new lambda.Template("%%.toArray()", o)));
	}

	for (var i = 0; i < this.types.length; i++) {
	    b.add(this.types[i].generate_encode(o.Index(i), l.Index(2*i),
						l.Index(2*i+1)));
	}
	b.add(type.Set(this.type));
	b.add(serialization.lambda.low_render_atoms(l, data));
	b.add(data.Set(new lambda.Template("%%.join(\"\")", l)));

	return b;
    }
});
serialization.Struct = serialization.Generated.extend({
    constructor : function(type, m, constr) {
	this.names = UTIL.keys(m);
	this.names = this.names.sort();
	this.constr = constr;
	//UTIL.log(this.names);
	var types = [];
	for (var i = 0; i < this.names.length; i++) {
	    //UTIL.log("pushing type "+ m[this.names[i]]);
	    types.push(m[this.names[i]]);
	}
	this.types = types;
	this.type = type||"_struct";
	this.base();
    },
    generate_decode : function(type, data, ret) {
	var b = new lambda.Block(data.scope);
	var l = type.scope.Var();
	b.add(l.Set(new lambda.Template("serialization.low_parse_atoms(%%)", data)));
	if (this.constr) {
	    var c = type.scope.Extern(this.constr);
	    b.add(ret.Set(new lambda.Template("(new %%())", c)));
	} else {
	    b.add(ret.Set({}));
	}

	for (var i = 0; i < this.names.length; i++) {
	    b.add(this.types[i].generate_decode(l.Index(2*i), l.Index(2*i+1),
						ret.Index(this.names[i])));
	}

	if (this.constr)
	    b.If("UTIL.functionp(%%.atom_init)", ret).add("%%.atom_init();", ret);
	return b;
    },
    toString : function() {
	    var l = this.types.concat();
	    for (var i = 0; i < l.length; i++) l[i] = l[i].toString();

	    return "Struct("+l.join(", ")+")";
    },
    generate_can_encode : function(o, ret) {
	if (this.constr) {
	    var c = o.scope.Extern(this.constr);
	    return ret.Set(new lambda.Template("%% instanceof %%", o, c));
	} else 
	    return ret.Set(new lambda.Template("typeof(%%) === %%", o,
					       "object"));
    },
    generate_encode : function(o, type, data) {
	var l = o.scope.Array(this.types.length*2);	
	var t = o.scope.Var();
	var b = new lambda.Block(data.scope);
	for (var i = 0; i < this.names.length; i ++) {
	    b.add(t.Set(o.Index(this.names[i])));
	    b.If("typeof(%%) === %%", t, "function").add(t.Set(new lambda.Template("%%.call(%%)", t, o)));
	    b.add(this.types[i].generate_encode(t, l.Index(2*i),
						l.Index(2*i+1)));
	}
	b.add(type.Set(this.type));
	b.add(data.Set(new lambda.Template("%%.join(\"\")", l)));
	return b;
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
serialization.Or = serialization.Generated.extend({
    constructor : function(t) {
	if (UTIL.arrayp(t))
	    this.types = t;
	else
	    this.types = Array.prototype.slice.apply(arguments);
    },
    toString : function() {
	    var l = this.types.concat();
	    for (var i = 0; i < l.length; i++) l[i] = l[i].toString();

	    return "Or("+l.join(", ")+")";
    },
    generate_can_encode : function(o, ret) {
	var b = new lambda.Block(o.scope);
	var t = o.scope.Var();
	for (var i = 0; i < this.types.length; i++) {
	    b.add(this.types[i].generate_can_encode(o, t));
	    var i = b.If("%%", t);
	    i.add(ret.Set(true));
	    i.add(b.Break());
	}
	b.add(ret.Set(false));
	return b;
    },
    generate_can_decode : function(type, data, ret) {
	var b = new lambda.Block(type.scope);
	var t = type.scope.Var();
	for (var i = 0; i < this.types.length; i++) {
	    b.add(this.types[i].generate_can_encode(type, data, t));
	    var i = b.If("%%", t);
	    i.add(ret.Set(true));
	    i.add(b.Break());
	}
	b.add(ret.Set(false));
	return b;
    },
    generate_decode : function(type, data, ret) {
	var b = new lambda.Block(type.scope);
	var t = type.scope.Var();
	for (var i = 0; i < this.types.length; i++) {
	    b.add(this.types[i].generate_can_decode(type, data, t));
	    var clause = b.If("%%", t);
	    clause.add(this.types[i].generate_decode(type, data, ret));
	    clause.add(b.Break());
	}
	b.add("UTIL.error(%%, %%, %%, %%)", "No type in %o to decode [%o, %o]", this, type, data);
	return b;
    },
    generate_encode : function(o, type, data) {
	var b = new lambda.Block(o.scope);
	var t = o.scope.Var();
	for (var i = 0; i < this.types.length; i++) {
	    b.add(this.types[i].generate_can_encode(o, t));
	    var clause = b.If("%%", t);
	    clause.add(this.types[i].generate_encode(o, type, data));
	    clause.add(b.Break());
	}
	b.add("UTIL.error(%%, %%, %%)", "No type in %o to encode %o", this, o);
	return b;
    }
});
serialization.Array = serialization.Generated.extend({
    constructor : function(type) { 
	this.type = "_list";
	this.etype = type;
	this.base();
    },
    generate_can_encode : function(o, ret) {
	return ret.Set(new lambda.Template("%% instanceof Array", o));
    },
    generate_decode : function(type, data, ret) {
	var b = new lambda.Block(type.scope);
	var l = type.scope.Var();
	var r = type.scope.Array(new lambda.Template("new Array(%%.length/2)", l));
	
	b.add(l.Set(new lambda.Template("serialization.low_parse_atoms(%%)", data)));
	b.add(r.Init());
	var f = r.Foreach();
	f.add(this.etype.generate_decode(
		l.Index(new lambda.Template("%%*2", f.key)),
		l.Index(new lambda.Template("%%*2+1", f.key)),
		r.Index(f.key)));
	b.add(f);
	b.add(ret.Set(r));
	return b;
    },
    generate_encode : function(o, type, data) {
	var b = new lambda.Block(type.scope);
	var l = type.scope.Array(new lambda.Template("new Array(%%*2)", o.Length()));
	b.add(l.Init());
	var f = lambda.Array.prototype.Foreach.call(o);
	f.add(this.etype.generate_encode(o.Index(f.key),
		    l.Index(new lambda.Template("%%*2", f.key)),
		    l.Index(new lambda.Template("%%*2+1", f.key))));
	b.add(f);
	b.add(type.Set(this.type));
	b.add(data.Set(new lambda.Template("%%.join(\"\")", l)));
	return b;
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
serialization.Null = new serialization.Singleton("_null", null);
serialization.Undefined = new serialization.Singleton("_undefined", undefined);
serialization.False = new serialization.Singleton("_false", false);
serialization.True = new serialization.Singleton("_true", true);
serialization.Boolean = new serialization.Or(serialization.True, serialization.False);
