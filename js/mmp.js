mmp = {};
mmp.uniform_cache = new Mapping();
/**
 * Create a Uniform object from the uniform str. Uniform objects are cached as long as they are created using this function. Therefore two uniform objects are the same if they represent the same uniform.
 */
mmp.get_uniform = function(str) {
	var uniform;

	if (mmp.uniform_cache.hasIndex(str)) {
		return mmp.uniform_cache.get(str);
	}

	uniform = new mmp.Uniform(str);
	mmp.uniform_cache.set(str, uniform);
	return uniform;
};
/**
 * Class representing uniforms.
 * @constructor
 * @property {String} uniform String representation of the uniform.
 * @property {String} object Path component of the uniform.
 * @property {String} name Name component of the uniform (i.e. object without type).
 * @property {String} host Host part of the uniform including the port number.
 */
mmp.Uniform = function(str) {
	var pos, root;

    if (str.substr(0,7) != "psyc://") {
		throw("Invalid uniform: " + str);	
    }
    this.uniform = str;
    str = str.slice(7);

    pos = str.indexOf("/");

    if (pos == -1) { // root
		this.host = str;
		root = str;
		this.is_person = function() { return 0; }
		this.is_room = function() { return 0; }
		// this seems stupid. avoid cycles
    } else {
		root = this.uniform.substr(0, 7+pos);
		this.host = str.substr(0, pos);
		str = str.slice(pos+1);

		this.object = str;
		this.type = str.charCodeAt(0);
		this.name = str.slice(1);

		if (this.type == 126) {
			this.is_person = function() { return 1; }
			this.is_room = function() { return 0; }
		} else if (this.type == 64) {
			this.is_person = function() { return 0; }
			this.is_room = function() { return 1; }

		} else {
			throw("Invalid uniform: " + this.str);
		}

		pos = str.indexOf("#");

		if (pos != -1) {
			this.base = str.substr(0, pos);
			this.channel = str.substr(pos+1, str.length-pos-1);
		} else {
			this.base = this.object;
		}
    }
	this.root = function() { return mmp.get_uniform(root); }
};
mmp.Uniform.prototype = {
	render : function(type) {
		switch (type) {
		case "_name": return this.name;
		case "_object": return this.object;
		case "_host": return this.host;
		case "_base": return this.base;
		}

		return this.uniform;
	},
	toString : function() {
		return this.uniform;
	},
	cmp : function(a) {
		var s1 = this.toString();
		var s2 = a.toString();
		return (s1 == s2) ? 0 : (s1 > s2) ? 1 : -1;
	},
	constructor : mmp.Uniform
};
mmp.Packet = Base.extend({
	constructor : function(data, vars) {
		this.data = data;
		this.vars = vars ? vars : {};
	},
	source : function(uniform) {
		if (uniform) {
			this.vars["_source"] = uniform;
		} else return this.vars["_source"];
	},
	target : function(uniform) {
		if (uniform) {
			this.vars["_target"] = uniform;
		} else return this.vars["_target"];
	},
	V : function(key) {
		return this.vars.hasOwnProperty(key);
	},
	v : function(key) {
		if (this.vars.hasOwnProperty(key)) {
			return this.vars[key];
		}
		return null;
	},
	forEach : function(fun, obj) {
		var name;
		if (!obj) obj = window;

		for (name in this.vars) if (this.vars.hasOwnProperty(name)) {
			fun.call(obj, name, this.vars[name]);
		}
	},
	id : function() {
		return this.v("_id");
	}
});
