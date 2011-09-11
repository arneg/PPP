
var lambda = {
    render_template : function(buf, s, a) {
	if (s) {
	    var c = -1;
	    var r = UTIL.split_replace(/%%/g, s, function (r) {
		var v = a[++c];
		if (UTIL.functionp(v)) {
		    return v;
		} else if (v instanceof lambda.Symbol) {
		    return v.name;
		} else if (v instanceof lambda.Template
			   || v instanceof lambda.Block) {
		    return v;
		} else {
		    return JSON.stringify(v);
		}
	    });
	    for (var i = 0; i < r.length; i++) {
		if (UTIL.stringp(r[i])) {
		    buf.add(r[i]);
		} else if (UTIL.functionp(r[i])) {
		    r[i](buf);
		} else r[i].render(buf);
	    }
	}
    },
};
lambda.Scope = Base.extend({
    constructor : function(symbols) {
	this.symbols = symbols||{};
    },
    Symbol : function() {
	var name = UTIL.unique_key(4, this.symbols);
	return this.symbols[name] = new lambda.Symbol(name);
    },
    Var : function(init) {
	var name = UTIL.unique_key(4, this.symbols);
	return this.symbols[name] = new lambda.Var(name, init);
    },
    Array : function(init) {
	var name = UTIL.unique_key(4, this.symbols);
	return this.symbols[name] = new lambda.Array(name, init);
    },
    Object : function(init) {
	var name = UTIL.unique_key(4, this.symbols);
	return this.symbols[name] = new lambda.Object(name, init);
    },
    Return : function(o) {
	return new lambda.Template("return %%;", o);
    }
});
lambda.Function = lambda.Scope.extend({
    constructor : function(symbols) {
	this.base(symbols);
	this.block = new lambda.Block();
	this.block.t = new Template("function()");
	this.block.add(UTIL.make_method(this, this.init_vars));
	this.args = {};
    },
    init_vars : function(buf) {
	var ret = [];	
	for (var i = 0; i < this.symbols; i++) {
	    if (this.symbols[i] instanceof lambda.Var)
		ret.push(this.symbols[i].Init());
	}
	if (ret.length) {
	    lambda.render_template(buf, "var %%"+UTIL.nchars(",%%", ret.length-1), ret);
	}
    },
    render : function(buf) {
	this.block.render(buf);	
    },
    $ : function(n) {
	if (!this.args[n]) this.args[n] = this.Var("arguments[" + (n-1) + "]");
	return this.args[n];
    },
    Arguments : function() {
	if (!this._arguments) this._arguments = this.Array("arguments");
	return this._arguments;
    },
    This : function() {
	if (!this._this) this._this = this.Var("this");
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
    },
    render : function(buf) {
	if (this.l)
	    buf.add(this.l+ ": ");
	this.statement().render(buf);
	buf.add("{\n");
	for (var i = 0; i < this.statements.length; i++) {
	    this.statements[i].render(buf);
	    buf.add(";\n");
	}
	buf.add("}\n");
    },
    label : function() {
	if (!this.label) {
	    this.label = this.scope.Symbol();
	}
	return this.label;
    },
    statement : function() {
	return this.t;
    },
    If : function(s) {
	return this.add(new lambda.If(this.scope,
	    new lambda.Template(s, Array.prototype.slice.call(arguments, 1))));
    },
    While : function(s) {
	return this.add(new lambda.While(this.scope,
	    new lambda.Template(s, Array.prototype.slice.call(arguments, 1))));
    },
    add : function(o) {
	this.statements.push(o);
	return o;
    },
    Break : function() {
	return new lambda.Template("break %%", this.label());
    },
    Function() {
	return new lambda.Function(UTIL.copy(this.symbols));
    }
});
lambda.Else = lambda.Block.extend({
    construtor : function(scope) {
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
lambda.gen_decode = function(scope, type, value, ret) {
    var loop = new lambda.AtomParse(scope, value);
    var ret = scope.Array();
    var i;
    for (..) {
	if (!i)
	    i = loop.If("%% == %%", loop.type, types[i].type);
	else 
	    i = i.Else().If("%% == %%", loop.type, types[i].type)
	i.add(types[i].gen_decode(scope, loop.type, loop.data, ret));
    }
    return loop;
}
lambda.Symbol = Base.extend({
    constructor : function(name) {
	this.name = name;
    }
});
lambda.Var = lambda.Symbol.extend({
    constructor : function(scope, name, init) {
	this.name = name;
	if (arguments.length > 1)
	    this.init = init;
    },
    Set : function(v) {
	return new lambda.Template("%% = %%", this, v);
    },
    Init : function() {
	if (this.hasOwnProperty("init")) {
	    return this.Set(this.init);
	} else return this;
    }
});
lambda.Array = lambda.Var.extend({
    Foreach : function() {
	var i = this.scope.Var();
	var v = this.scope.Var();
	var f = new lambda.For(i.Set(0),
			       new lambda.Template("%% < %%.length", i, this),
			       new lambda.Template("%%++", i));
	f.add(v.Set("%%[%%]", this, i));
	f.i = i;
	f.value = v;
	return f;
    }
});
lambda.Mapping = lambda.Var.extend({
    Foreach : function() {
	var key = this.scope.Var();
	var v = this.scope.Var();
	var f = new lambda.Loop(this.scope);
	f.t = new Template("for (%% in %%) if (%%.hasOwnProperty(%%))",
			      key, this, this, key);
	f.add(v.Set("%%[%%]", this, key));
	f.key = key;
	f.value = v;
	return f;
    }
});
