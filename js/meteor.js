if( typeof XMLHttpRequest == "undefined" ) XMLHttpRequest = function() {
  try { return new ActiveXObject("Msxml2.XMLHTTP.6.0") } catch(e) {}
  try { return new ActiveXObject("Msxml2.XMLHTTP.3.0") } catch(e) {}
  try { return new ActiveXObject("Msxml2.XMLHTTP") } catch(e) {}
  try { return new ActiveXObject("Microsoft.XMLHTTP") } catch(e) {}
  throw new Error( "This browser does not support XMLHttpRequest." )
};
/**
 * @namespace Meteor js connection namespace.
 */
meteor = new Object();
/**
 * Limit for the incoming buffer. When the incoming XMLHttpRequest object buffer grows larger than this, the connection is reinitiated.
 */
meteor.BUFFER_MAX = 1 << 16; // limit for incoming buffer, exceeding this buffer triggers a reconnect
/**
 * Meteor connection class. This is usually used with Atom serialization on top. Use psyc.Client if unsure.
 * @param {String} url URL of the Meteor connection endpoint.
 * @param {Function} callback Function to be called when data has been received.
 * @param {Function} error Function to be called when a fatal error occures.
 * @constructor
 * @example
 * var connection;
 * var incoming = function(data) {
 * 	document.write("Received data: " + data);
 * 	connection.send("Hello World.\n");
 * }
 * connection = new meteor.Connection("http://example.org/meteor/", incoming, alert);
 * connection.init();
 */
meteor.Connection = function(url, callback, error) {
    this.url = url;
    this.buffer = "";
    this.callback = callback;
    this.error = error;
	this.client_id = 0;
	this.new_incoming = 0;
	this.incoming = 0;
	this.outgoing = 0;
	this.init_xhr = 0;
	this.reconnect = 1; // do a reconnect on close
};
meteor.Connection.prototype = {
	new_incoming_state_change : function() {
		var con = this.meteor;
		con.error("new_incoming state is " + this.readyState);
		// we should check here for buffer length. maybe set a max
		// amount to shut down the main one ungracefully
		if (this.readyState >= 3) {
			con.connect_incoming();
		} else if (window.opera) {
			var xhr = this;
			setTimeout((function() {
				meteor.Connection.prototype.new_incoming_state_change.call(xhr);
			}), 200);
		}
	},
	connect_new_incoming : function() {
		if (this.new_incoming) {
			// we already have one new incoming and are waiting for the
			// main one to shut down

			if (this.new_incoming.readyState == 4) {
			// someone is too fast for us.	
			// TODO: we have to check for data in new_incoming,
			// not sure what to do with it. we can probably savely
			// parse it in case of atoms.
				if (meteor.debug) meteor.debug("New connection already finished.\n");
			} else return this.connect_incoming();
		}

		if (meteor.debug) meteor.debug("Connecting new incoming.\n");

		var xhr = new XMLHttpRequest();
		this.new_incoming = xhr;
		xhr.pos = 0;
			
		xhr.open("POST", this.url + "?" + this.client_id, true);
		//xhr.overrideMimeType("text/plain; charset=ISO-8859-1");
		if (xhr.overrideMimeType) xhr.overrideMimeType('text/plain; charset=x-user-defined');
		xhr.onreadystatechange = this.new_incoming_state_change;
		xhr.meteor = this;
		xhr.send("");
	},
	incoming_state_change : function() {
		var con = this.meteor;
		var status;
		if (meteor.debug) meteor.debug("incoming in readyState "+this.readyState);
		if (this.readyState >= 3) {
			//this.readyState = 2;
			
			// stupid workaround for IE which was written by 
			// stupid assholes
			try {
				status = this.status;
			} catch(e) {
				// this is ie country
				// this is ie
				if (meteor.debug) meteor.debug("fucking ie");
			}

			if (meteor.debug) meteor.debug("http status code: "+status);
			if (status == 200) {
				var length = this.responseBody ? this.responseBody.length : this.responseText.length;
				var response = this.responseBody ? this.reponseBody : this.responseText;

				if (length > this.pos) {
					var str;

					if (this.pos) {
						str = (response.slice(this.pos));
					} else {
						str = response;
					}

					// ifdef firefox or safari
					if (navigator.userAgent.indexOf("Firefox") != -1 || navigator.userAgent.indexOf("Safari") != -1) {
						var t = new Array;
						for (var i = 0; i < str.length; i++) {
							t.push(str.charCodeAt(i) & 0xff);
						}
						str = String.fromCharCode.apply(window, t);
					}
					// endif

					try {
						if (con.callback.obj) {
							con.callback.call(con.callback.obj, str);
						} else {
							con.callback(str);
						}
					} catch (error) {
						if (meteor.debug) meteor.debug("ERROR: "+error);
					}

					this.pos = length;
				}

				if (this.readyState == 4 || this.pos >= meteor.BUFFER_MAX) {
					if (con.reconnect) con.connect_new_incoming();
				}
			} else {
			// this throws an exception in firefox. brain
			//	con.error(this.statusText);
			}
		}
	},
	incoming_on_error : function() {
		if (meteor.debug) meteor.debug("INCOMING ERROR!");
		this.meteor.connect_new_incoming();
	},
	connect_incoming : function(xhr) {
		if (!xhr) {
			if (this.new_incoming) {
				xhr = this.new_incoming;
			} else throw("you need to call new_incoming() first. no this.new_incoming.");
		}
		
		if (this.incoming) {
			if (this.incoming.readyState != 4) {
				return;
			}

			try { this.incoming.abort(); } catch (e) {}
		}

		if (this.operatimer) {
			clearTimeout(this.operatimer);
			this.operatimer = null;
		}

		xhr.onreadystatechange = this.incoming_state_change;
		xhr.onerror = this.incoming_on_error;
		this.error("moved new incoming to incoming.\n");
		this.new_incoming = 0;
		this.incoming = xhr;
		meteor.Connection.prototype.incoming_state_change.call(xhr);

		// This code polls the xhr for new data in case opera is used. its necessary
		// because opera does not trigger an event if new data is available in state 3.
		if (window.opera) {
			var fun = function() {
				meteor.Connection.prototype.incoming_state_change.call(xhr);
			};
			this.operatimer = setInterval(fun, 100);
			if (meteor.debug) meteor.debug("timer: "+this.operatimer);
		}
	},
	outgoing_state_change : function() {
		var con = this.meteor;

		if (this.readyState == 4) {

			if (this.status == 200) {
				
				con.connect_outgoing();
			} else {
				con.error(this.statusText);
			}
		}
	},
	connect_outgoing : function() {
		var xhr;

		if (this.outgoing) {
			this.outgoing.abort();
			xhr = this.outgoing;
		} else {
			xhr = new XMLHttpRequest();
			this.outgoing = xhr;
		}
		//this.error("outgoing state is " + xhr.readyState);

		xhr.open("POST", this.url + "?" + this.client_id, true);
		// we do this charset hackery because we have internal utf8 and plain ascii
		// for the rest of atom. this is supposed to be a binary transport
		xhr.setRequestHeader("Content-Type", "application/binary");
		xhr.onreadystatechange = this.outgoing_state_change;
		xhr.meteor = this;
		this.ready = 1;

		if (this.buffer.length > 0) this.write();
	},
	init_state_change : function(change_event) { // fetch the client_id and go
		var con = this.meteor;
		if (this.readyState == 4) {
			if (this.status == 200) {
				con.client_id = this.responseText;
				if (meteor.debug) meteor.debug("got client ID " + con.client_id);
				con.init_xhr = null;
				con.connect_outgoing();
				con.connect_new_incoming();
			} else {
				con.error(this.statusText);
			}
			this.meteor = null;
			//console.debug("not yet in readyState 4\n");
		}
	},
	/**
	 * Initialize the connection. This needs to be called before any data can be sent or received.
	 */
	init : function() { // fetch the client_id and go
		var xhr = new XMLHttpRequest();
		xhr.meteor = this;
		this.reconnect = 1;
		this.init_xhr = xhr;
		//this.error("initialization state is " + xhr.readyState);

		xhr.onreadystatechange = this.init_state_change;
		xhr.meteor = this;
		xhr.open("GET", this.url, true);
		xhr.send("");
	},
	/**
	 * Close incoming connection and clean up cyclic references.
	 */
	destruct : function() {
		var list = [this.init_xhr, this.new_incoming, this.incoming, this.outgoing];
		for (var t in list) {
			t = list[t];
			try {
				if (t) {
					t.abort();
					t.meteor = null;
				}
			} catch(e) { }
		}
		this.init_xhr = null;
		this.incoming = null;
		this.new_incoming = null;
		this.outgoing = null;
		this.callback = null;
		this.error = null;
	},
	/**
	 * Send some data.
	 * @param {String} data String to be sent.
	 */
	send : function(data) {
		// check for status
		meteor.debug("Appending ("+data.substr(data.length-40, 39)+")\n");
		meteor.debug(this.ready +" "+this.will_write);
		this.buffer += data;

		if (this.client_id && this.ready && !this.will_write) {
			// ifdef firefox
			//this.outgoing.setRequestHeader("Content-Length", this.buffer.length);
			// endif
			var self = this;
			var cb = function() {
				self.will_write = 0;
				self.write();
			}
			this.will_write = 1;		
			window.setTimeout(cb, 20);
		}
	},
	write : function() {
		this.outgoing.send(this.buffer);   
		meteor.debug("Sending ("+this.buffer.substr(this.buffer.length-40, 39)+")\n");
		this.ready = 0;
		this.buffer = "";
	}
};
// the params handed by the user could be prototyped with a
// msg and something more
meteor.CallbackWrapper = function(params, mapping) {
	this.mapping = mapping;
	this.params = params;	
};
meteor.CallbackWrapper.prototype = {
	msg : function(message) {
		if (!this.params.source || this.params.source == message.vars.get("_source")) {
			if (this.params.object) {
				if (this.params.cb) {
					return this.params.cb.call(this.params.object, message, this);
				}

				return this.params.object.msg(message, this);
			} else {
				return this.params.cb(message, this);
			}
		}
	},
	active : function() {
		return this.mapping == 0 ? 0 : 1;
	},
	unregister : function() {
		if (this.mapping == 0) return;

		var list = this.mapping.get(this.params.method);

		for (var i = 0; i < list.length; i++) {
			if (list[i] == this) {
				list.splice(i, 1);
			}
		}

		this.mapping = 0;
	}
};
