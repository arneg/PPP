/*
Copyright (C) 2010  Arne Goedeke

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
WIDGET = {};
WIDGET.StateMachine = Base.extend({
	constructor : function(transitions, actions) {
		this.t = transitions;
		this.a = {};
		for (var i in actions) if (actions.hasOwnProperty(i)) {
			if (UTIL.arrayp(actions[i])) this.a[i] = actions[i];
			else this.registerEvent(i, actions[i]);
		}
		this.state = "start";
	},
	trigger : function(e) {
		if (this.t[this.state].hasOwnProperty(e)) {
			var nstate = this.t[this.state][e];
			this.callEvent(this.state+">"+nstate, this.state, nstate, e);
			this.callEvent("<"+this.state, this.state, nstate, e);
			this.callEvent(">"+nstate, this.state, nstate, e);
			this.state = nstate;
		}
		this.callEvent(e, this.state, e);
	},
	callEvent : function(e) {
		if (this.a.hasOwnProperty(e)) {
			var args = [ this ].concat(Array.prototype.slice.call(arguments, 1));
			for (var i = 0; i < this.a[e].length; i++) this.a[e][i].apply(window, args);
		}
	},
	registerEvent : function(e, fun) {
		if (this.a.hasOwnProperty(e)) this.a[e].push(fun);
		else this.a[e] = [ fun ];
	}
});
WIDGET.Base = WIDGET.StateMachine.extend({
	constructor : function(node, states, actions) {
		this.node = node;
		var transitions = {
			start : {}
		};

		if (states.hover) {
			transitions.start.mouseover = "hover";
			transitions.hover = { mouseout : "start" };
			node.onmouseover = UTIL.make_method(this, this.trigger, "mouseover");
			node.onmouseout = UTIL.make_method(this, this.trigger, "mouseout");
		}

		if (states.clicked) {
			transitions.start.mousedown = "clicked";
			transitions.clicked = { mouseup : "start" };
			node.onmousedown = UTIL.make_method(this, this.trigger, "mousedown");
			node.onmouseup = UTIL.make_method(this, this.trigger, "mouseup");
		}

		var l = [ "mouseover", "mouseout", "mousedown", "mouseup", "click", "dblclick" ];
		for (var i = 0; i < l.length; i++) {
			if (actions.hasOwnProperty(l[i]) && !node["on"+l[i]]) {
			    node["on"+l[i]] = UTIL.make_method(this, this.trigger, l[i]);
			}
		}

		this.base(transitions, actions);
	},
});
WIDGET.SimpleButton = WIDGET.Base.extend({
	constructor : function(node, classes, actions) {
		if (classes.hover) {
			actions["start>hover"] = function() { UTIL.addClass(node, classes.hover) };
			actions["hover>start"] = function() { UTIL.removeClass(node, classes.hover) };
		}

		this.base(node, classes, actions);
	},
});
