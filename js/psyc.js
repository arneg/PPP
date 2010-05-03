psyc = {
    STOP : 1,
    GOON : 0
};
psyc.Types = {};
psyc.Types.default_polymorphic = function() {
	var pol = new serialization.Polymorphic();
	var method = new serialization.Method();
	// integer and string come first because they should not get overwritten by 
	// method and float
	pol.register_type("_string", "string", new serialization.String());
	pol.register_type("_integer", "number", new serialization.Integer());
	pol.register_type("_float", "float", new serialization.Float());
	pol.register_type("_method", "string", method);
	//pol.register_type("_message", psyc.Types.Message, new serialization.Message(method, pol, pol));
	pol.register_type("_mapping", Mapping, new serialization.Mapping(pol, pol));
	pol.register_type("_list", Array, new serialization.Array(pol));
	pol.register_type("_time", mmp.Date, new serialization.Date());
	pol.register_type("_uniform", mmp.Uniform, new serialization.Uniform());
	return pol;
}
psyc.Types.Message = serialization.Base.extend({
	constructor : function(vars, data) {
		this.vtype = vars;
		this.dtype = data;
		this.type = "_message";
	},
	can_decode : function(atom) {
		var abbrevs = mmp.abbreviations(atom.type);
		if (abbrevs.length > 1) switch (abbrevs[abbrevs.length - 2]) {
		case "_message":
		case "_request":
		case "_error":
		case "_notice":
		case "_update":
		case "_status":
			return 1;
		}
		return 0;
	},
	can_encode : function(o) {
		return o instanceof psyc.Message;
	},
	decode : function(atom) {
		var p = new serialization.AtomParser();
		var l = p.parse(atom.data);
		var vars = this.vtype.decode(l[0]);		
		var data = this.dtype.decode(l[1]);

		return new psyc.Message(atom.type, data, vars);
	},
	encode : function(o) {
		var str = "";
		str += this.vtype.encode(o.vars).render();		
		str += this.dtype.encode(o.data).render();

		return new serialization.Atom(o.method, str);
	}
});
/**
 * PSYC message class.
 * @constructor
 * @param {String} method PSYC method
 * @param {mmp#Vars} vars variables
 * @param {String} data Payload
 * @property {String} method PSYC method
 * @property {mmp#Vars} vars variables
 * @property {String} data Payload
 */
psyc.Message = mmp.Packet.extend({
	constructor : function(method, data, vars) {
		this.method = method;
		this.base(data||"", vars||{});
		// TODO: this is a hack
		this.vars.remove("_timestamp");
	},
	toString : function() {
		var ret = "psyc.Message("+this.method+", ([ ";
		ret += this.vars.toString();
		ret += "]))";
		return ret;
	},
	isMethod : function(method) {
		return this.method.indexOf(method) == 0;
	}
});
psyc.Base = mmp.Base.extend({
	constructor : function(server, uniform) {
		this.base(server, uniform);
		this.message_signature = new psyc.Types.Message(new serialization.Vars({ _ : psyc.Types.default_polymorphic() }), new serialization.String());
		this.callbacks = new Mapping();
	},
	/**
	 * Register for certain incoming messages. This can be used to implement chat tabs or handlers for certain message types.
	 * @params {Object} params Object containing the properties "method", "callback" and optionally "source". For all incoming messages matching "method" 
	 * and "source" the callback is called. The "source" property should be of type mmp.Uniform.
	 * @returns A wrapper object of type meteor.CallbackWrapper. It can be used to unregister the handler.
	 */
	register_method : function(params) {
		var wrapper = new meteor.CallbackWrapper(params, this.callbacks);
		
		if (this.callbacks.hasIndex(params.method)) {
			var list = this.callbacks.get(params.method);
			list.push(wrapper);
		} else {
			this.callbacks.set(params.method, new Array( wrapper ) );
		}

		return wrapper;
	},
	msg : function(p) {
		if (!this.base(p)) return; // drop old packets

		if (this.message_signature.can_decode(p.data)) { // this is a psyc mc or something
		    var m = this.message_signature.decode(p.data);
		    var method = m.method;
		    var none = 1;

		    for (var t = method; t; t = mmp.abbrev(t)) {
			    if (UTIL.functionp(this[t])) {
				    none = 0;
				    try {
					if (psyc.STOP == this[t].call(this, p, m)) {
						return psyc.STOP;
					}
				    } catch (error) {
					if (meteor.debug) meteor.debug("error when calling "+t+" in "+this+": %o", error);
				    }
			    }
		    }

		    if (none && meteor.debug) {
			    meteor.debug("No handler for "+method+" in "+this);	
		    }

		    return psyc.GOON;
		} else if (meteor.debug) meteor.debug("Bad method "+p);
	},
 	sendmsg : function(target, method, data, vars) {
		var m = this.message_signature.encode(new psyc.Message(method, data, vars));
		this.send(target, m);
	},
	/**
	 * Send a packet. This should be of type psyc.Message.
	 * @params {Object} packet Message to send.
	 */
	send : function(target, m) {
		if (m instanceof psyc.Message) m = this.message_signature.encode(m);
		this.base(target, m);
	},
	_ : function(p, m) {
		var method = m.method;
		for (var t = method; t; t = mmp.abbrev(t)) {
			if (!this.callbacks.hasIndex(t)) continue;

			none = 0;
			var list = this.callbacks.get(t);
			var stop = 0;

			for (var j = 0; j < list.length; j++) {
				try {
					if (psyc.STOP == list[j].msg(p, m)) {
						stop = 1;
					}
				} catch (error) {
					if (meteor.debug) meteor.debug(error);
				}
			}

			// we do this to stop only after all callbacks on the same level have been handled.
			if (stop) {
				return psyc.STOP;
			}
		}
	}
});
