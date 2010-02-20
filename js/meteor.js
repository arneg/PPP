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
meteor.dismantle = function(xhr) {
	delete xhr.onreadystatechange;
	try { xhr.abort(); } catch (e) {};
};
meteor.debug = function() {
	if (window.console && window.console.log) {
		if (window.console.firebug) {
			window.console.log.apply(window, arguments);
		} else { //this is IE
			window.console.log(arguments[0]);
		}
	}
};
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
meteor.Connection = function(url, vars, callback, error) {
    this.url = url;
    this.vars = vars;
    this.buffer = "";
    this.callback = callback;
    this.error = error;
    this.async = true;
    this.new_incoming = 0;
    this.incoming = 0;
    this.outgoing = 0;
    this.init_xhr = 0;
    this.pos = 0;
    this.reconnect = 1; // do a reconnect on close
};
meteor.Connection.prototype = {
	reconnect_incoming : function() {
		meteor.debug("reconnecting due to timeout.\n");
		if (this.new_incoming) {
			meteor.dismantle(this.new_incoming);
			delete this.new_incoming;
		}
		if (this.incoming) {
			meteor.dismantle(this.incoming);
			delete this.incoming;
		}
		this.connect_new_incoming();
	},
	new_incoming_state_change : function(xhr) {
		meteor.debug("new_incoming state is " + xhr.readyState);
		// we should check here for buffer length. maybe set a max
		// amount to shut down the main one ungracefully
		if (xhr.readyState >= 3) {
			this.connect_incoming();
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
				meteor.debug("New connection already finished.\n");
			} else return this.connect_incoming();
		}

		meteor.debug("Connecting new incoming.\n");

		var xhr = new XMLHttpRequest();
		this.new_incoming = xhr;
			
		xhr.open("POST", UTIL.make_url(this.url, this.vars), true);
		// both opera and IE dont handle binary data correctly.
		if (!window.opera && navigator.appName != 'Microsoft Internet Explorer') {
			xhr.setRequestHeader("Content-Type", "application/octet-stream");
		}
		//xhr.overrideMimeType("text/plain; charset=ISO-8859-1");
		if (xhr.overrideMimeType) xhr.overrideMimeType('text/plain; charset=x-user-defined');
		xhr.onreadystatechange = UTIL.make_callback(this, this.new_incoming_state_change);
		xhr.send("");
	},
	set_nonblocking : function() {
		this.async = true;
		this.outgoing.async = true;
		this.outgoing.onreadystatechange = UTIL.make_callback(this, this.outgoing_state_change);
	},
	set_blocking : function() {
		this.async = false;
		this.outgoing.onreadystatechange = null;
		this.outgoing.async = false;
	},
	incoming_state_change : function(xhr) {
		var s;

		if (xhr.readyState >= 3) {
			//this.readyState = 2;
			
			// workaround for IE
			try {
				s = xhr.status;
			} catch(e) {
				// this is ie country
				// this is ie
				meteor.debug("fucking ie");
			}

			if (s == 200) {
				var length = xhr.responseBody ? xhr.responseBody.length : xhr.responseText.length;

				meteor.debug("length: %d > %d", length, this.pos);

				if (length > this.pos) {
					meteor.debug((length-this.pos)+" bytes received in readyState "+xhr.readyState);
					var str;

					try {
						if (window.opera) {
							str = xhr.responseText.slice(this.pos);
						} else if (xhr.responseBody) {
							str = xhr.responseBody.join("");
						} else {
							str = xhr.responseText.slice(this.pos);
							var t = str.split("");
							for (var i = 0; i < str.length; i++) {
								t[i] = t[i].charCodeAt(0) & 0xff;
							}
							str = String.fromCharCode.apply(window, t);
						}

						meteor.debug("calling callback: %o with %db of data", this.callback, str.length);
						this.callback(str);
					} catch (error) {
						meteor.debug("ERROR: "+error);
					}

					this.pos = length;
				}

				if (xhr.readyState == 4 || this.pos >= meteor.BUFFER_MAX) {
					if (this.operatimer) {
						clearTimeout(this.operatimer);
						delete this.operatimer;
					}
					if (this.reconnect) this.connect_new_incoming();
				}
			} else {
			// this throws an exception in firefox. brain
			//	con.error(this.statusText);
			}
		}
	},
	incoming_on_error : function() {
		meteor.debug("INCOMING ERROR!");
		window.setTimeout(UTIL.make_callback(this, this.connect_new_incoming), 500);
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

			meteor.dismantle(this.incoming);
		}

		if (this.operatimer) {
			clearTimeout(this.operatimer);
			delete this.operatimer;
		}

		xhr.onreadystatechange = UTIL.make_callback(this, this.incoming_state_change);
		xhr.onerror = UTIL.make_callback(this, this.incoming_on_error);
		meteor.debug("moved new incoming to incoming.");
		this.new_incoming = 0;
		this.incoming = xhr;
		this.incoming_state_change(xhr);

		// This code polls the xhr for new data in case opera is used. its necessary
		// because opera does not trigger an event if new data is available in state 3.
		if (window.opera) {
			this.operatimer = setInterval(UTIL.make_callback(this, this.incoming_state_change), 100);
			meteor.debug("timer: "+this.operatimer);
		}
	},
	outgoing_onerror : function(xhr) {
		meteor.debug("error while connecting outgoing. data lost, we should write back to buffer and retry.");
	},
	outgoing_state_change : function(xhr) {
		meteor.debug("outgoing state is "+xhr.readyState);

		if (xhr.readyState == 4) {

			if (xhr.status == 200) {
				this.connect_outgoing();
			} else {
				this.error(xhr.statusText);
			}
		}
	},
	connect_outgoing : function() {
		var xhr;

		meteor.debug("connecting new outgoing.");

		if (this.outgoing) {
			this.outgoing.abort();
			xhr = this.outgoing;
		} else {
			xhr = new XMLHttpRequest();
			this.outgoing = xhr;
		}
		//this.error("outgoing state is " + xhr.readyState);

		xhr.open("POST", UTIL.make_url(this.url, this.vars), this.async);
		// we do this charset hackery because we have internal utf8 and plain ascii
		// for the rest of atom. this is supposed to be a binary transport
		if (this.async) {
		    xhr.onreadystatechange = UTIL.make_callback(this, this.outgoing_state_change);
		    xhr.onerror = UTIL.make_callback(this, this.outgoing_onerror);
		}
		this.ready = 1;

		if (this.buffer.length > 0) this.write();
	},
	init_state_change : function(xhr) { // fetch the client_id and go
		if (xhr.readyState == 4) {
			if (xhr.status == 200) {
				this.vars["id"] = xhr.responseText;
				meteor.debug("got client ID " + this.vars["id"]);

				// we can reuse this object
				this.outgoing = this.init_xhr;

				this.connect_outgoing();
				this.connect_new_incoming();
			} else if (xhr.status == 404) {
				this.error(xhr.responseText);
			} else {
				this.error(xhr.statusText);
			}

			delete this.init_xhr;
		}
	},
	/**
	 * Initialize the connection. This needs to be called before any data can be sent or received.
	 */
	init : function() { // fetch the client_id and go
		var xhr = new XMLHttpRequest();
		this.reconnect = 1;
		this.init_xhr = xhr;
		//this.error("initialization state is " + xhr.readyState);

		xhr.onreadystatechange = UTIL.make_callback(this, this.init_state_change);
		xhr.open("GET", UTIL.make_url(this.url, this.vars), true);
		xhr.send("");
	},
	/**
	 * Close incoming connection and clean up cyclic references.
	 */
	close : function() {
		var list = [this.init_xhr, this.new_incoming, this.incoming, this.outgoing];
		for (var i = 0; i < list.length; i++) {
			var t = list[i];
			try {
				if (t) {
					meteor.dismantle(t);
				}
			} catch(e) { }
		}
		delete this.init_xhr;
		delete this.incoming;
		delete this.new_incoming;
		delete this.outgoing;
		delete this.callback;
		delete this.error;
	},
	/**
	 * Send some data.
	 * @param {String} data String to be sent.
	 */
	send : function(data) {
		meteor.debug("sending "+data.length+" bytes");
		// check for status
		this.buffer += data;

		if (this.vars["id"] && this.ready) { 
		    if (!this.async) {
			this.write();
		    } else if (!this.will_write) {
			// ifdef firefox
			//this.outgoing.setRequestHeader("Content-Length", this.buffer.length);
			// endif
			this.will_write = true;
			this.write();
		    }
		}
	},
	write : function() {
		this.will_write = false;
		this.outgoing.onreadystatechange = UTIL.make_callback(this, this.outgoing_state_change);
		//meteor.debug("outgoing state change is %o", this.outgoing.onreadystatechange);
		if (this.outgoing.sendAsBinary) {
			this.outgoing.setRequestHeader("Content-Type", "application/octet-stream");
			this.outgoing.setRequestHeader("Content-Length", this.buffer.length);
			this.outgoing.sendAsBinary(this.buffer);
		} else {
			this.outgoing.send(this.buffer);   
		}
		meteor.debug("writing "+this.buffer.length+" bytes\n");
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
	msg : function(p, message) {
		var ok = true;
		if ((this.params.source && this.params.source != p.source())
		||  (this.params.context && this.params.context != p.v("_context"))
		||  (this.params.target && this.params.target != p.target())
		) {
			ok = false;
			meteor.debug(p.toString()+" is not the one.\n");
		}

		if (ok) {
			if (this.params.object) {
				if (this.params.cb) {
					return this.params.cb.call(this.params.object, p, message, this);
				}

				return this.params.object.msg(p, message, this);
			} else {
				return this.params.cb(p, message, this);
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
