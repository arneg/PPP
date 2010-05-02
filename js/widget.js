WIDGET = {};
WIDGET.StateMachine = Base.extend({
	constructor : function(transitions, actions) {
		this.t = transitions;
		this.a = {};
		for (var i in actions) if (actions.hasOwnProperty(i)) {
			if (UTILS.arrayp(actions[i])) this.a[i] = actions[i];
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
	},
	hasEvent : function(e) {
		return this.a.hasOwnProperty(e);
	}
});
WIDGET.Base = WIDGET.StateMachine.extend({
	constructor : function(node, states, actions) {
		this.node = node;
		var transitions = {
			start : {}
		};

		if (UTIL.arrayp(states)) {
			var m = {};
			for (var i = 0; i < states.length; i++) {
				m[states[i]] = 1;
			}
			states = m;
		}

		if (!actions) actions = {};

		if (states.hover) {
			transitions.start.mouseover = "hover";
			transitions.hover = { mouseout : "start" };
			node.onmouseover = UTIL.make_method(this, this.trigger, "mouseover");
			node.onmouseout = UTIL.make_method(this, this.trigger, "mouseout");
		}

		if (states.clicked) {
			if (states.hover) {
			    transitions.hover.mousedown = "clicked";
			} else {
			    transitions.start.mousedown = "clicked";
			}
			// we go back to start because someone could click and then move out of
			// the widget
			transitions.clicked = { mouseup : "start" };

			node.onmousedown = UTIL.make_method(this, this.trigger, "mousedown");
			node.onmouseup = UTIL.make_method(this, this.trigger, "mouseup");
		}

		if (states.blur) {
			transitions.start.blur = "blur";
			transitions.blur = { focus : "start" };
		}

		var l = [ "mouseover", "mouseout", "mousedown", "mouseup", "click", "dblclick" ];
		for (var i = 0; i < l.length; i++) {
			if (actions.hasOwnProperty(l[i]) && !node["on"+l[i]]) {
			    node["on"+l[i]] = UTIL.make_method(this, this.trigger, l[i]);
			}
		}

		this.base(transitions, actions);

		if (!actions.hover) this.registerEvent("hover", UTIL.make_method(window, UTIL.replaceClass, this.node, "start", "hover"));
		if (!actions.clicked) this.registerEvent("clicked", UTIL.make_method(window, UTIL.replaceClass, this.node, "start", "clicked"));
	},
	registerEvent : function(e, fun) {
		if (!this.hasEvent(e)) this.node["on"+e] = UTIL.make_method(this, this.trigger, e);
		this.base(e, fun);
	}
});
WIDGET.SimpleButton = WIDGET.Base.extend({
	constructor : function(node, classes, actions) {
		if (classes.hover) {
			actions["start>hover"] = function() { UTIL.addClass(node, classes.hover) };
			actions["hover>start"] = function() { UTIL.removeClass(node, classes.hover) };
		}

		this.base(node, classes, actions);
	}
});
WIDGET.Cycle = Base.extend({
	constructor : function() {
		this.items = [];
	},
	cycle : function(n) {
		if (this.items.length == 1) return;
		this.items[0].trigger("blur");
		if (n > 0) while (n-- > 0) this.items.push(this.items.shift());
		else if (n < 0) while (n++ > 0) this.items.unshift(this.items.pop());
		this.items[0].trigger("focus");
	},
	addItem : function(widget) {
		this.items.push(widget);
		widget.registerEvent(">blur", UTIL.make_method(window, UTIL.addClass, widget.node, "blur"));
		widget.registerEvent("<blur", UTIL.make_method(window, UTIL.removeClass, widget.node, "blur"));

		if (this.items.length == 1) {
			widget.trigger("focus");
		} else {
			widget.trigger("blur");
		}
	},
	addButton : function(button, step) {
		button.registerEvent("click", UTIL.make_method(this, this.cycle, step||1));
	}
});
