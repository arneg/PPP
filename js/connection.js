if( typeof XMLHttpRequest == "undefined" ) XMLHttpRequest = function() {
  try { return new ActiveXObject("Msxml2.XMLHTTP.6.0") } catch(e) {}
  try { return new ActiveXObject("Msxml2.XMLHTTP.3.0") } catch(e) {}
  try { return new ActiveXObject("Msxml2.XMLHTTP") } catch(e) {}
  try { return new ActiveXObject("Microsoft.XMLHTTP") } catch(e) {}
  throw new Error( "This browser does not support XMLHttpRequest." )
};
psyc = new Object();
psyc.render_atom = function() {
    return this.type + " " + String(this.data.length) + " " + this.data;
};
psyc.atom_parser = function() {
    this.buffer = "";
    this.reset = function() {
	this.type = 0;
	this.length = -1;
    };
    this.reset();
    this.parse = function(str) {
	this.buffer += str;

	var ret = new Array();
	var t = 0;
	while (t = this._parse()) {
	    ret.push(t);
	}
	return ret;
    };
    this._parse = function() {
	if (!this.type) {
	    var pos = this.buffer.indexOf(" ");

	    if (pos == -1) {
		// check here for bogus data
//		if (re[0].search(/(_\w+)+/) != 0) {
//		    throw("bad atom\n");
//		}
		return 0;
	    } else if (pos < 2) {
		throw("bad atom.");
	    }

	    this.type = this.buffer.substr(0, pos);
	    this.buffer = this.buffer.slice(pos+1);
	}

	if (this.length == -1) {
	    var pos = this.buffer.indexOf(" ");

	    if (pos == -1) {
		return 0;
	    } else if (pos == 0) {
		throw("bad atom.");
	    }

	    this.length = parseInt(this.buffer.substr(0, pos));
	    if (this.length < 0 || this.length.toString() != this.buffer.substr(0, pos)) {
		throw("bad length in atom.\n");
	    }
	    this.buffer = this.buffer.slice(pos+1);
	}

	if (this.length > this.buffer.length) {
	    // add a sanity check. we do not want superlarge data strings, i guess
	    return 0;
	}

	var a;

	if (this.length == this.buffer.length) {
	    a = new psyc.atom(this.type, this.buffer);
	    this.buffer = "";
	} else {
	    a = new psyc.atom(this.type, this.buffer.substr(0,this.length));
	    this.buffer = this.buffer.slice(this.length);
	}
	this.reset();
	
	return a;
    };
    
};
psyc.atom = function(type, data) {
    this.type = type;
    this.data = data;
    this.render = psyc.render_atom;
};
psyc.connection = function(url, callback, error) {
    this.url = url;
    this.schmu = "sdfsdf";
    this.callback = callback;
    this.error = error;
    this.reconnect = function() {
	if (typeof this.xhr != "undefined") {
	    this.xhr.connection = 0;
	}
	var xhr = new XMLHttpRequest();
	this.xhr = xhr;
	this.xhr.connection = this;

	this.xhr.onreadystatechange = function () {
	    if (xhr.readyState == 4) {

		if (xhr.status == 200) {
		    xhr.connection.callback(xhr.responseBody);
		    xhr.connection.reconnect();
		} else {
		    xhr.connection.error(xhr.statusText);
		}
	    } else {
		xhr.connection.error("on the way");
		//console.debug("not yet in readyState 4\n");
	    }
	};
	this.xhr.open("POST", this.url, true);
    };
    this.send = function(data) {
	this.xhr.send(data);   
    };
};
