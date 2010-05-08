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
mmp.methodre = /^(_(\w)+)+$/;
mmp.methodp = function(method) {
    if (!UTIL.stringp(method)) return false;
    return mmp.methodre.test(method);
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
		this.get_object = function(path) {
			return mmp.get_uniform(this.uniform+"/"+path);
		};
		this.root = function() { return this; }
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
		} else if (this.type == 36) {
			this.is_person = function() { return 0; }
			this.is_room = function() { return 0; }
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
		this.get_object = function(path) { return this.root().get_object(path); }
		this.root = function() { return mmp.get_uniform(root); }
    }
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
	    	return Math.round(this.date.getTime() / 1000);
	};
};
/**
 * Does a one-step abbreviation of a psyc method. For instance, _message_public turns into _message. Returns 0 if no further abbreviation is possible.
 * @param {String} method PSYC method
 */
mmp.abbrev = function(method) {
	var i = method.lastIndexOf("_");
	if (i == -1) {
		return 0;
	} else if (i == 0) {
		if (method.length == 1) return 0;
		return "_";
	} else {
		return method.substr(0, i);
	}
}
mmp.abbreviations = function(method) {
	var ret = new Array();
	do { ret.push(method); } while( (method = mmp.abbrev(method)) );

	return ret;
}
/**
 * Generic PSYC Variable class. This should be used to represent PSYC message variables. 
 * @constructor
 * @augments Mapping
 */
mmp.Vars = Base.extend({
	constructor : function() {
	    if (arguments.length == 1 && typeof(arguments[0]) == "object") {
			this.m = arguments[0];
	    } else if (arguments.length & 1) {
			throw("odd number of mapping members.");
	    } else {
			this.m = {};
			for (var i = 0; i < arguments.length; i += 2) {
				this.m[arguments[i]] = arguments[i+1];
			}
	    }
	},
	get : function(key) {
	    do {
		if (this.m.hasOwnProperty(key)) {
		    return this.m[key];
		}
	    } while (key = mmp.abbrev(key));

	    return undefined;
	},
	getIndex : function(key) {
	    do {
		if (this.m.hasOwnProperty(key)) {
		    return key;
		}
	    } while (key = mmp.abbrev(key));

	    return false;
	},
	hasIndex : function(key) {
	    return this.m.hasOwnProperty(key);
	},
	set : function(k, v) {
	    this.m[k] = v;
	},
	remove : function(k) {
	    delete this.m[k];
	},
	forEach : function(callback, context) {
	    if (context) for (var k in this.m) if (this.m.hasOwnProperty(k)) {
		callback.call(context, k, this.m[k]);
	    } else for (var k in this.m) if (this.m.hasOwnProperty(k)) {
		callback(k, this.m[k]);
	    }
	},
	toString : function() {
	    return "mmp.Vars(" + this.m + ")";
	},
	clone : function(t) {
		var m = new mmp.Vars(t);
		this.forEach(function(key, val) {
			if (!m.hasIndex(key)) m.set(key, val);
		}, this);
		return m;
	},
	append : function(v) {
		v.forEach(function(key, val) {
			this.set(key, val);
		}, this);
	}
});
mmp.Packet = Base.extend({
	constructor : function(data, vars) {
		this.data = data;
		if (vars instanceof mmp.Vars) {
			this.vars = vars;
		} else if (vars) {
			this.vars = new mmp.Vars(vars);
		} else {
			this.vars = new mmp.Vars();
		}
		if (!this.vars.hasIndex("_timestamp")) {
			this.vars.set("_timestamp", new mmp.Date());
		}
	},
	source : function(uniform) {
		if (uniform) {
			this.vars.set("_source", uniform);
		} else return this.vars.get("_source_relay");// inheritence || this.vars.get("_source");
	},
	target : function(uniform) {
		if (uniform) {
			this.vars.set("_target", uniform);
		} else return this.vars.get("_target");
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
mmp.Base = UTIL.EventSource.extend({
	constructor : function(server, uniform) {
		this.base();
		this.default_vars = new mmp.Vars();
		this.server = server;
		this.uniform = uniform;
		this.states = new Mapping();
	},
	getState : function(uniform) {
		if (this.states.hasIndex(uniform)) {
			return this.states.get(uniform);
		}
		var state = {
			local_id : 0,
			remote_id : -1,
			last_in_sequence : -1,
			missing : new Mapping(),
			cache : {}
		};
		this.states.set(uniform, state);

		return state;
	},
	deleteState : function(uniform) {
		this.states.remove(uniform);
	},
	msg : function(p) {
		// This part is essentially copied and turned into the corresponding js
		var id = p.v("_id");
		var ack = p.v("_ack");

		var state = this.getState(p.v("_source"));

		if (0 == id && state.remote_id != -1) {
		    //meteor.debug("%o received initial packet from %O\n", this.uniform, p.v("_source"));
		    this.deleteState(p.v("_source"));
		    state = this.getState(p.v("_source"));
		    // TODO we should check what happened to _ack. maybe we dont have to throw
		    // away all of it
		}

		//meteor.debug("%o received %d (ack: %d, remote: %d, seq: %d)\n", this.uniform, id, ack, state.remote_id, state.last_in_sequence);

		if (id == state.remote_id + 1) {
		    if (state.last_in_sequence == state.remote_id) state.last_in_sequence = id;
		} else if (id > state.remote_id + 1) { // missing messages
		    // we will request retrieval only once
		    // maybe use missing = indices(state.missing) here?
		    for (var i = state.remote_id + 1, j = 0; i < id; i++, j++) {
				state.missing[i] = true;
		    }

		    meteor.debug("missing: %o\n", state.missing);
		    this.sendmsg(p.v("_source"), "_request_retrieval", 0, { "_ids" : state.missing.indices() });
		    state.remote_id = id;
		} else if (id <= state.remote_id) { // retrieval
		    meteor.debug("got retransmission of %d (still missing: %s)\n", id, state.missing.indices().join(", "));
		    if (state.missing.hasIndex(id)) {
			delete state.missing[id];
			if (!sizeof(state.missing)) state.last_in_sequence = state.remote_id;
			else state.last_in_sequence = Math.min.apply(Math, state.missing.indices())-1;
		    } return false; // drop this packet
		}

		if (id > state.remote_id) state.remote_id = id;

		// would like to use something like filter(state.cache, Function.curry(`>)(ack)) ...
		for (var i = ack; state.cache.hasOwnProperty(i); i--) delete state.cache[i];

		return true;
	},
	sendmsg : function(target, method, data, vars) {
		throw("mmp.Base.sendmsg needs to be implemented by the subclass.");
	},
	send : function(target, data, relay) {
		var state = this.getState(target);
		var id = state.local_id++;
		var vars = this.default_vars.clone({
			_target : target,
			_id : id,
			_ack : state.last_in_sequence,
		}); 

		if (relay) {
			if (relay instanceof mmp.Vars) {
				vars.append(relay);
			} else if (relay instanceof mmp.Uniform) {
				vars.set("_source_relay", relay);
			} else throw("Bad vars: "+relay);
		}

		var p = new mmp.Packet(data, vars);
		state.cache[id] = p;
		this.server.msg(p);
		return p;
	}
});
