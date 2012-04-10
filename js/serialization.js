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
    AtomRender : Base.extend({
	constructor : function(scope, n) {
	    this.scope = scope;
	    this.C = scope.Array(new lambda.Template("new Array(%%)", arguments.length > 1 ? (UTIL.intp(n) ? 2*n : n) : 0));
	    this.i = scope.Var(0);
	},
	render : function(t, o) {
	    var b = new lambda.Block(this.scope);
	    var type = this.C.Index(this.i);
	    var data = this.C.Index(this.i.Add(1));
	    b.add(t.generate_encode(o, type, data));
	    b.add(type.Increment(" ", data.Length(), " "));
	    b.add(this.i.Increment(2));
	    return b;
	},
	finish : function(ret) {
	    var b = new lambda.Block(this.scope);
	    b.add(ret.Set(new lambda.Template("(%%).join(\"\")", this.C)));
	   // b.add(this.i.Set(0));
	    return b;
	},
	Init : function() {
	    return this.C.Init();
	}
    })
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
    var re = /(\w+) (\d+) /g;
    re.lastIndex = 0;
    var r, length;

    while (i < s.length) {
	r = re.exec(s);
	if (!r) {
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
	if (arguments.length)
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
	this.buffer = this.buffer.slice(pos+1);
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
    },
    toString : function() {
	return "serialization.Generated("+this.type+")";
    },
    decode : function(atom) {
	if (!this._decode) {
	    var f = new lambda.Function();
	    var ret = f.Var();
	    f.block.add(this.generate_decode(f.$(1).Index("type"),
					 f.$(1).Index("data"),
					 ret));
	    f.block.add(f.Return(ret));
	    this._decode = f.compile();
	}
	return this._decode(atom);
    },
    can_decode : function(atom) {
	if (!this._can_decode) {
	    var f = new lambda.Function();
	    var ret = f.Var();
	    f.block.add(this.generate_can_decode(f.$(1).Index("type"),
					 f.$(1).Index("data"),
					 ret));
	    f.block.add(f.Return(ret));
	    this._can_decode = f.compile();
	}
	return this._can_decode(atom);
    },
    encode : function(o) {
	if (!this._encode) {
	    var f = new lambda.Function();
	    var ret = f.Var();
	    var data = f.Var();
	    f.block.add(this.generate_encode(f.$(1), ret, data));
	    f.block.add("%% = new serialization.Atom(%%, %%)", ret, ret, data);
	    f.block.add(f.Return(ret));
	    this._encode = f.compile();
	}
	var t = this._encode(o);
	return t;
    },
    can_encode : function(o) {
	if (!this._can_encode) {
	    var f = new lambda.Function();
	    var ret = f.Var();
	    f.block.add(this.generate_can_encode(f.$(1), ret));
	    f.block.add(f.Return(ret));
	    this._can_encode = f.compile();
	}
	return this._can_encode(o);
    },
    render : function(o) {
	if (!this._render) {
	    var f = new lambda.Function();
	    var ret = f.Var();
	    var data = f.Var();
	    f.block.add(this.generate_encode(f.$(1), ret, data));
	    f.block.add("%% += \" \"+ %%.length +\" \"+ %%", ret,
			data, data);
	    f.block.add(f.Return(ret));
	    this._render = f.compile();
	}
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
		var t = types[i].encode(o);
		return t;
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
	if (arguments.length)
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
	return ret.Set(new lambda.Template("%% === %%", o, c));
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
	return ret.Set(new lambda.Template("typeof(%%) === 'string'", o));
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
serialization.JSON = serialization.Generated.extend({
    constructor : function() {
	this.type = "_json";
	this.base();
    },
    generate_can_encode : function(o, ret) {
	return ret.Set(new lambda.Template("true", o));
    },
    generate_decode : function(type, data, ret) {
	return ret.Set(new lambda.Template("JSON.parse(UTF8.decode(%%))", data));
    },
    generate_encode : function(o, type, data) {
	var b = new lambda.Block(data.scope);
	b.add(type.Set(this.type));
	b.add(data.Set(new lambda.Template("UTF8.encode(JSON.stringify(%%))", o)));
	return b;
    }
});
serialization.Integer = serialization.Generated.extend({
    constructor : function() { 
	this.type = "_integer";
	this.base();
    },
    generate_can_encode : function(o, ret) {
	return ret.Set(new lambda.Template("typeof(%%) === \"number\" && %% % 1.0 == 0.0", o, o));
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
	return ret.Set(new lambda.Template("typeof(%%) === 'string'", o));
    },
    generate_decode : function(type, data, ret) {
	return ret.Set(data);
    },
    generate_encode : function(o, type, data) {
	var b = new lambda.Block(data.scope);
	b.add(type.Set(this.type));
	b.add(data.Set(o));
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
	b.If("!%%", ret.Index("src")).add(ret.Set(null));
	return b;
    },
    generate_encode : function(o, type, data) {
	var pos = o.scope.Var();
	var b = new lambda.Block(data.scope);
	b.add(pos.Set(new lambda.Template("%%.src.indexOf(\",\")", o)));
	b.If("%% === -1", pos)
	    .add("UTIL.error(%%)","broken dataurl.\n");
	b.add(o.Set(new lambda.Template("UTIL.Base64.decode(%%.src.substr(%%))", o, pos.Add(1))));
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
serialization.Mapping = serialization.Generated.extend({
    constructor : function(mtype, vtype) { 
	this.mtype = mtype;
	this.vtype = vtype;
	this.type = "_mapping";
    },
    constr : Mapping,
    toString : function() {
	    return "Mapping()";
    },
    generate_can_encode : function(o, ret) {
	var c = ret.scope.Extern(this.constr);
	return ret.Set(new lambda.Template("%% instanceof %%", o, c));
    },
    generate_decode : function(type, data, ret) {
	var loop;
	var k = ret.scope.Var();
	var v = ret.scope.Var();
	var l = ret.scope.Array();
	var c = ret.scope.Extern(this.constr);
	var b = new lambda.Block(ret.scope);
	b.add(l.Set(new lambda.Template("serialization.low_parse_atoms(%%)", data)));
	b.add(ret.Set(new lambda.Template("new (%%)()", c)));

	var f = l.Foreach(4);
	f.add(this.mtype.generate_decode(l.Index(f.key), l.Index(f.key.Add(1)), k));
	f.add(this.vtype.generate_decode(l.Index(f.key.Add(2)), l.Index(f.key.Add(3)), v));
	f.add(new lambda.Template("(%%).set(%%, %%)", ret, k, v));
	b.add(f);

	return b;
    },
    generate_encode : function(o, type, data) {
	var b = new lambda.Block(data.scope);
	var buf = new serialization.lambda.AtomRender(data.scope);
	var cb = data.scope.Function();
	cb.block.add(buf.render(this.mtype, cb.$(1)));
	cb.block.add(buf.render(this.vtype, cb.$(2)));

	b.add(new lambda.Template("(%%).forEach(%%)", o, cb));
	b.add(type.Set(this.type));
	b.add(buf.finish(data));
	return b;
    }
});
serialization.Object = serialization.Generated.extend({
    constructor : function(vtype) { 
	this.vtype = vtype;
	this.type = "_mapping";
	this.base();
    },
    toString : function() {
	return "Object()";
    },
    generate_can_encode : function(o, ret) {
	return ret.Set(new lambda.Template("%% instanceof Object", o));
    },
    generate_decode : function(type, data, ret) {
	var loop;
	var k = ret.scope.Var();
	var v = ret.scope.Var();
	var l = ret.scope.Array();
	var b = new lambda.Block(ret.scope);
	b.add(l.Set(new lambda.Template("serialization.low_parse_atoms(%%)", data)));
	b.add(ret.Set({}));

	var f = l.Foreach(4);
	f.add(serialization.string.generate_decode(l.Index(f.key), l.Index(f.key.Add(1)), k));
	f.add(this.vtype.generate_decode(l.Index(f.key.Add(2)), l.Index(f.key.Add(3)), v));
	f.add(ret.Index(k).Set(v));
	b.add(f);

	return b;
    },
    generate_encode : function(o, type, data) {
	var buf = new serialization.lambda.AtomRender(o.scope);
	var b = new lambda.Block(type.scope);
	b.add(buf.Init());
	if (this.vtype instanceof serialization.Range) b.add(lambda.Beacon());
	var f = lambda.Mapping.prototype.Foreach.call(o);
	f.add(buf.render(serialization.string, f.key));
	f.add(buf.render(this.vtype, f.value));
	b.add(f);
	b.add(type.Set(this.type));
	b.add(buf.finish(data));
	return b;
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
	    return ret.Set(new lambda.Template("(%%) instanceof Array && %%.length === %%", o, o, this.types.length));
	}
    },
    generate_encode : function(o, type, data) {
	var b = new lambda.Block(data.scope);
	var buf = new serialization.lambda.AtomRender(data.scope);
	b.add(buf.Init());

	if (this.p) {
	    b.If("!((%%) instanceof Array)", o).add(o.Set(
		new lambda.Template("%%.toArray()", o)));
	}

	for (var i = 0; i < this.types.length; i++) {
	    b.add(buf.render(this.types[i], o.Index(i)));
	}
	b.add(type.Set(this.type));
	b.add(buf.finish(data));

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
	    b.If("(%%.atom_init)", ret).add("%%.atom_init();", ret);
	//b.add(ret.Index("_atom_cache").Set(new lambda.Template("[ %%, %% ]", type, data)));
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

	/*
	var cache = b.If("!!(%%)", o.Index("_atom_cache"));
	cache.add(type.Set(o.Index("_atom_cache").Index(0)));
	cache.add(data.Set(o.Index("_atom_cache").Index(1)));
	cache.add(b.Break());
	*/

	for (var i = 0; i < this.names.length; i ++) {
	    b.add(t.Set(o.Index(this.names[i])));
	    b.If("typeof(%%) === %%", t, "function").add(t.Set(new lambda.Template("%%.call(%%)", t, o)));
	    b.add(this.types[i].generate_encode(t, l.Index(2*i),
						l.Index(2*i+1)));
	    b.add(l.Index(2*i).Increment(" ", l.Index(2*i+1).Length(), " "));
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
		if ((types[n]) instanceof Function)
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
	if (t instanceof Array)
	    this.types = t;
	else
	    this.types = Array.prototype.slice.apply(arguments);
	this.base();
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
	var buf = new serialization.lambda.AtomRender(o.scope, o.Length());
	var b = new lambda.Block(type.scope);
	b.add(buf.Init());
	var f = lambda.Array.prototype.Foreach.call(o);
	f.add(buf.render(this.etype, o.Index(f.key)));
	b.add(f);
	b.add(type.Set(this.type));
	b.add(buf.finish(data));
	return b;
    }
});
serialization.SimpleSet = serialization.Array.extend({
	constructor : function() {
	    this.base(new serialization.Or(
					   serialization.integer,
					   serialization.string))
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
serialization.integer = new serialization.Integer();
serialization.string = new serialization.String();
serialization.json = new serialization.JSON();
serialization.date = new serialization.Date();
serialization.image = new serialization.Image();
