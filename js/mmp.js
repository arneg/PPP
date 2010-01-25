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
/**
 * Returns the value associated with key or an abbreviation of key.
 * @param {String} key PSYC variable name.
 */
// not being able to use inheritance here stinks like fish.
mmp.Date = function(timestamp) {
	this.date = new Date();
	if (timestamp) {
	    this.date.setTime(timestamp * 1000);
	}
	this.render = function(type) {
		var fill = function(n, length) {
			var ret = n.toString();
			for (var i = length - ret.length; i > 0; i--) {
				ret = "0"+ret;	
			}

			return ret;
		}
		switch (type) {
		case "_month": return this.date.getMonth();
		case "_month_utc": return this.date.getUTCMonth();
		case "_weekday": return this.date.getDay();
		case "_monthday": return this.date.getDate();
		case "_monthday_utc": return this.date.getUTCDate();
		case "_minutes": return fill(this.date.getMinutes(), 2);
		case "_minutes_utc": return fill(this.date.getUTCMinutes(), 2);
		case "_seconds": return fill(this.date.getSeconds(), 2);
		case "_seconds_utc": return fill(this.date.getUTCSeconds(), 2);
		case "_timezone_offset": return this.date.getTimezoneOffset();
		case "_year": return fill(this.date.getFullYear(), 4);
		case "_year_utc": return fill(this.date.getUTCFullYear(), 4);
		case "_hours": return this.date.getHours();
		case "_hours_utc": return this.date.getUTCHours();
		}
		return this.date.toLocaleString();
	};
	this.toString = function() {
		return this.date.toLocaleString();
	};
	this.toInt = function() {
	    	return this.date.getTime() / 1000;
	};
};
/**
 * Generic PSYC Variable class. This should be used to represent PSYC message variables. 
 * @constructor
 * @augments Mapping
 */
mmp.Vars = function() {
	this.get = function(key) {
		do {
			if (this.hasIndex(key)) {
				return mmp.Vars.prototype.get.call(this, key);
			}
		} while (key = mmp.abbrev(key));

		return undefined;
	};
	this.hasIndex = function(key) {
	    return (this.get(key) != undefined);
	}

	Mapping.call(this);

	if (arguments.length == 1) {
		var vars = arguments[0];

		for (var i in vars) {
			if (vars.hasOwnProperty(i)) {
				this.set(i, vars[i]);
			}
		}
	} else if (arguments.length & 1) {
		throw("odd number of mapping members.");
	} else for (var i = 0; i < arguments.length; i += 2) {
        this.set(arguments[i], arguments[i+1]);
    }
};
mmp.Vars.prototype = new Mapping();
mmp.Vars.prototype.constructor = mmp.Vars;
mmp.Packet = Base.extend({
	constructor : function(data, vars) {
		this.data = data;
		if (vars.prototype == mmp.Vars) {
			this.vars = vars;
		} else {
			this.vars = new mmp.Vars(vars);
		}
		if (!this.vars.hasIndex("_timestamp")) {
			this.vars.set("_timestamp", new mmp.Date());
		}
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
		return this.vars.hasIndex(key);
	},
	v : function(key) {
		return this.vars.get(key);
	},
	forEach : function(fun, obj) {
		var name;
		if (!obj) obj = window;

		var cb = function() {
		    fun.call(obj, name, this.vars.get(name));
		};

		this.vars.forEach(cb, this);
	},
	id : function() {
		return this.v("_id");
	}
});
