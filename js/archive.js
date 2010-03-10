/*
Copyright (C) 2010 Arne Goedeke

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
ARCHIVE = {};
ARCHIVE.SEARCH_URL = "http://www.archive.org/advancedsearch.php";
ARCHIVE.DETAIL_URL = "http://www.archive.org/details/";
ARCHIVE.TIMEOUT = -1;
ARCHIVE.Requests = {};
ARCHIVE.SearchRequest = Base.extend({
	constructor : function(id, callback, script) {
		this.id = id;
		this.callback = callback;
		this.script = script;
	},
	response : function(result) {
		document.getElementsByTagName("head")[0].removeChild(this.script);
		delete ARCHIVE.Requests[this.id];
		this.callback(result);
	},
	timeout : function() {
		this.response(ARCHIVE.TIMEOUT);
	}
});
ARCHIVE.Search = Base.extend({
	constructor : function(what, params) {
		this.vars = {
		    output : "json",
		    q : what,
		    rows : (!!params && !!params.per_page) ? params.per_page : 10
		};
		this.vars["fl[]"] = [ "avg_rating", "description", "title", "mediatype", "downloads", "language", "contributor", "identifier" ];
		//this.vars["fl[]"] = "title,identifier";
	},
	search : function(page, callback) {

		var id = UTIL.get_unique_key(3, ARCHIVE.Requests);
		var args = UTIL.merge_objects(this.vars, {
			page : page,
			callback : "ARCHIVE.Requests[\""+id+"\"].response"
		});


		var script = document.createElement("script");
		script.type = "text/javascript";
		script.src = UTIL.make_url(ARCHIVE.SEARCH_URL, UTIL.merge_objects(this.vars, args));
		var r = new ARCHIVE.SearchRequest(id, callback, script);
		ARCHIVE.Requests[id] = r;
		document.getElementsByTagName("head")[0].appendChild(script);
		window.setTimeout(UTIL.make_method(r, r.timeout), 100000);
	}
});
ARCHIVE.Item = Base.extend({
	constructor : function(id) {
		this.identifier = id;
		this.callbacks = [];
	},
	get_url : function() {
		return ARCHIVE.DETAIL_URL + this.identifier;
	},
	fetch_info : function(callback) {
		if (this.info && this.info != ARCHIVE.TIMEOUT) {
		    callback(this.info);
		    return;
		}

		this.callbacks.push(callback);

		if (this.request_token) return;

		this.request_token = UTIL.get_unique_id(3, ARCHIVE.Requests);

		var script = document.createElement("script");
		script.type = "text/javascript";
		script.src = UTIL.make_url(this.get_url, { output : "json", callback : "ARCHIVE.Requests[\""+this.request_tokenٌ+"\"].result"});
		ARCHIVE.Requests[this.request_token] = this;
		document.getElementsByTagName("head")[0].appendChild(script);
		window.setTimeout(UTIL.make_method(this, this.timeout), 100000);
		this.script = script;
	},
	result : function(r) {
		this.info = r;
		delete ARCHIVE.Requests[this.request_token];
		delete this.request_token;
		document.getElementsByTagName("head")[0].removeChild(this.script);
		delete this.script;

		var list = this.callbacks;
		this.callbacks = [];
		for (var i = 0; i < list.length; i++) {
		    list[i](r);
		}
	},
	timeout : function() {
		this.result(ARCHIVE.TIMEOUT);
		delete this.info;
	},
});
