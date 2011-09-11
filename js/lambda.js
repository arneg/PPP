
var lambda = {
    render_template : function(buf, s, a) {
	if (s) {
	    var c = -1;
	    var r = UTIL.split_replace(/%%/g, s, function (r) {
		if (c + 1 >= a.length) {
		    throw("not enough arguments to '"+s+"'");
		}
		var v = a[++c];
		if (UTIL.functionp(v)) {
		    return v;
		} else if (v instanceof lambda.Symbol
			   || v instanceof lambda.Var) {
		    return v;
		} else if (v instanceof lambda.Template
			   || v instanceof lambda.Block) {
		    return v;
		} else {
		    return JSON.stringify(v)||"undefined";
		}
	    });
	    for (var i = 0; i < r.length; i++) {
		if (UTIL.stringp(r[i])) {
		    buf.add(r[i]);
		} else if (UTIL.functionp(r[i])) {
		    r[i](buf);
		} else if (UTIL.objectp(r[i]) && r[i].render) {
		    r[i].render(buf);
		} else throw("dont know how to render "+ r[i]+" in '"+s+"'");
	    }
	}
    },
};
lambda.Scope = Base.extend({
    constructor : function(symbols) {
	this.symbols = symbols||{};
    },
    Symbol : function() {
	var name = UTIL.get_unique_key(4, this.symbols);
	return this.symbols[name] = new lambda.Symbol(name);
    },
    Var : function(init) {
	var name = UTIL.get_unique_key(4, this.symbols);
	return this.symbols[name] = arguments.length ? new lambda.Var(this, name, init)
					 : new lambda.Var(this, name);
    },
    Array : function(init) {
	var name = UTIL.get_unique_key(4, this.symbols);
	return this.symbols[name] = arguments.length ? new lambda.Array(this, name, init)
					 : new lambda.Array(this, name);
    },
    Object : function(init) {
	var name = UTIL.get_unique_key(4, this.symbols);
	return this.symbols[name] = arguments.length ? new lambda.Object(this, name, init)
					 : new lambda.Object(this, name);
    },
    Return : function(o) {
	return new lambda.Template("return %%", o);
    }
});
lambda.Function = lambda.Scope.extend({
    constructor : function(symbols) {
	this.base(symbols);
	this.block = new lambda.Block(this);
	this.block.t = new lambda.Template("function()");
	this.block.add(UTIL.make_method(this, this.init_vars));
	this.args = {};
	this.constants = [];
	this.cvalues = [];
    },
    compile : function() {
	var b = new UTIL.StringBuilder();
	var f;
	if (this.constants.length) {
	    lambda.render_template(b, "(function(%%"+UTIL.nchars(",%%", this.constants.length-1)+"){ return ", this.constants);
	}
	this.render(b);
	if (this.constants.length) {
	    b.add(";})");     
	}
	try {
	    f = eval(b.get());
	} catch (e) {
	    UTIL.error("failed to compile(%o): %o", e, b.get());
	}
	if (this.constants.length) {
	    f = f.apply(window, this.cvalues);     
	}
	f.raw = b.get();
	f.preety = function() {
	    var t = this.raw.split("\n");
	    for (var i = 0; i < t.length; i++)
		t[i] = (i+1)+": "+t[i];
	    return t.join("\n");
	}
	return f;
    },
    Extern : function(v) {
	var s = this.Symbol();
	this.constants.push(s);
	this.cvalues.push(v);
	return s;
    },
    init_vars : function(buf) {
	var ret = [];	
	for (var i in this.symbols) {
	    if (!this.symbols.hasOwnProperty(i)) continue;
	    if (this.symbols[i] instanceof lambda.Var
	      && !this.symbols[i].inited)
		ret.push(this.symbols[i].Init());
	}
	if (ret.length) {
	    lambda.render_template(buf, "var %%"+UTIL.nchars(",%%", ret.length-1), ret);
	}
    },
    render : function(buf) {
	buf.add("(");
	this.block.render(buf);	
	buf.add(")");
    },
    $ : function(n) {
	if (!this.args[n]) this.args[n] = this.Var(new lambda.Template("arguments[%%]", n-1));
	return this.args[n];
    },
    Arguments : function() {
	if (!this._arguments) this._arguments = this.Array(new lambda.Template("Array.prototype.slice.call(arguments)"));
	return this._arguments;
    },
    This : function() {
	if (!this._this) this._this = this.Var(new lambda.Template("this"));
	return this._this;
    }
});
lambda.Template = Base.extend({
    constructor : function(s) {
	this.s = s;
	this.args = Array.prototype.slice.call(arguments, 1);
    },
    render : function(buf) {
	lambda.render_template(buf, this.s, this.args);
    }
});
lambda.Block = Base.extend({
    constructor : function(scope) {
	this.scope = scope;
	this.statements = [];
    },
    render : function(buf) {
	if (this._label) {
	    this._label.render(buf);
	    buf.add(": ");
	}
	this.statement().render(buf);
	buf.add("{\n");
	for (var i = 0; i < this.statements.length; i++) {
	    if (!this.statements[i]) {
		throw("statement "+i+" is undefined");
	    }
	    lambda.render_template(buf, "%%;\n", [ this.statements[i] ]);
	    buf.add(";\n");
	}
	buf.add("}\n");
    },
    label : function() {
	if (!this._label) {
	    this._label = this.scope.Symbol();
	}
	return this._label;
    },
    statement : function() {
	return this.t ? this.t : new lambda.Template("");
    },
    If : function() {
	return this.add(new lambda.If(this.scope,
	    UTIL.create(lambda.Template,
			Array.prototype.slice.call(arguments))
	));
    },
    While : function(s) {
	return this.add(new lambda.While(this.scope,
	    UTIL.create(lambda.Template,
			Array.prototype.slice.call(arguments))
	));
    },
    add : function(o) {
	if (UTIL.stringp(o)) {
	    o = UTIL.create(lambda.Template, Array.prototype.slice.call(arguments));
	}
	if (!o) throw("missing argument to add!");
	this.statements.push(o);
	return o;
    },
    Break : function() {
	return new lambda.Template("break %%", this.label());
    },
    Function : function() {
	return new lambda.Function(this.symbols);
    },
    toString : function() {
	return "Block("+(this.t ? this.t.s : "<void>")+")";
    }
});
lambda.Else = lambda.Block.extend({
    constructor : function(scope) {
	this.base(scope);
	this.t = new lambda.Template(" else ");
    }
});
lambda.If = lambda.Block.extend({
    constructor : function(scope, t) {
	this.base(scope);
	this.t = new lambda.Template("if (%%)", t);
    },
    render : function(buf) {
	this.base(buf);
	if (this.e) {
	   this.e.render(buf);
	}
    },
    Else : function() {
	if (!this.e)
	    this.e = new lambda.Else(this.scope);
	return this.e;
    }
});
lambda.Loop = lambda.Block.extend({
    Continue : function() {
	return new lambda.Template("continue %%", this.label());
    }
});
lambda.While = lambda.Loop.extend({
    constructor : function(scope, t) {
	this.base(scope);
	this.t = new lambda.Template("while (%%)", t);
    }
});
lambda.For = lambda.Loop.extend({
    constructor : function(scope, tinit, tcheck, tloop) {
	this.base(scope);
	this.t = new lambda.Template("for (%%;%%;%%)",
				     tinit, tcheck, tloop);
    }
});
lambda.Symbol = Base.extend({
    constructor : function(name) {
	this.name = name;
    },
    render : function(buf) {
	buf.add(this.name);
    },
    Index : function(key) {
	var b = new UTIL.StringBuilder();
	lambda.render_template(b, "%%[%%]", [this, key]);
	return new lambda.Symbol(b.get());
    },
    Length : function() {
	var b = new UTIL.StringBuilder();
	lambda.render_template(b, "%%.length", [this]);
	return new lambda.Symbol(b.get());
    }
});
lambda.Var = lambda.Symbol.extend({
    constructor : function(scope, name, init) {
	this.scope = scope;
	this.name = name;
	if (arguments.length > 2)
	    this.init = init;
    },
    Set : function(v) {
	return new lambda.Template("%% = %%", this, v);
    },
    Init : function() {
	this.inited = true;
	if (this.hasOwnProperty("init")) {
	    return this.Set(this.init);
	} else return this;
    },
    Index : function(key) {
	var b = new UTIL.StringBuilder();
	lambda.render_template(b, "%%[%%]", [this, key]);
	return new lambda.Var(this.scope, b.get());
    }
});
lambda.Array = lambda.Var.extend({
    constructor : function(scope, name, init) {
	if (UTIL.intp(init)) {
	    init = new lambda.Template("new Array(%%)", init);
	}
	this.base(scope, name, init);
    },
    Foreach : function() {
	var i = this.scope.Var();
	var v = this.scope.Var();
	var f = new lambda.For(this.scope, i.Set(0),
			       new lambda.Template("%% < %%.length", i, this),
			       new lambda.Template("%%++", i));
	f.add(v.Set(this.Index(i)));
	f.key = i;
	f.value = v;
	return f;
    }
});
lambda.Mapping = lambda.Var.extend({
    Foreach : function() {
	var key = this.scope.Var();
	var v = this.scope.Var();
	var f = new lambda.Loop(this.scope);
	f.t = new lambda.Template("for (%% in %%) if (%%.hasOwnProperty(%%))",
			      key, this, this, key);
	f.add(v.Set(this.Index(key)));
	f.key = key;
	f.value = v;
	return f;
    }
});
function f() {
    var f = new lambda.Function();
    var i = f.block.If("%% < 0", f.$(1));
    i.add(f.Return(-1));
    i.Else().add(f.Return(1));
    return f;
}
function add(v) {
    var f = new lambda.Function();
    v = f.Extern(v);
    var ret = f.Var(0);
    var l = f.Arguments().Foreach();
    l.add("%% += %%", ret, l.value);
    f.block.add(l);
    f.block.add("%% += %%", ret, v);
    f.block.add(f.Return(ret));
    return f;
}
var b = new UTIL.StringBuilder();
