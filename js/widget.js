Widget = {};
Widget.StateMachine = Base.extend({
	constructor : function(transitions, actions) {
		this.t = transitions;
		this.a = {};
		for (var i in actions) if (actions.hasOwnProperty(i)) {
			if (UTIL.arrayp(actions[i])) this.a[i] = actions[i];
			else this.registerEvent(i, actions[i]);
		}
		this.state = "start";
	},
	trigger : function(e, ev) {
		if (!ev && UTIL.App.is_ie && window.event) ev = window.event;
		//console.log("%o.trigger(%s)", this, e);
		if (this.t[this.state].hasOwnProperty(e)) {
			var nstate = this.t[this.state][e];
			this.callEvent(this.state+">"+nstate, this.state, nstate, e, ev);
			this.callEvent(this.state+">", this.state, nstate, e, ev);
			this.callEvent(">"+nstate, this.state, nstate, e, ev);
			this.state = nstate;
		}
		this.callEvent(e, this.state, e, ev);
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
	},
	addTransition : function(from, when, to) {
		if (!this.t[from]) this.t[from] = {};
		if (!this.t[from][when]) this.t[from][when] = to;
		else if (this.t[from][when] != to) throw("Transition in "+from+" on "+when+" is already pointing at "+this.t[from][when]);
	}
});
Widget.Base = Widget.StateMachine.extend({
	constructor : function(node, states, actions) {
		this.node = node;
		var transitions = {
			start : {}
		};
		if (!actions) actions = {};

		if (typeof(states) == "object" && !(states instanceof Array)) 
			for (var key in states) if (states.hasOwnProperty(key)) transitions[key] = states[key];

		this.base(transitions, actions);

		if (UTIL.arrayp(states)) {
			for (var i = 0; i < states.length; i++) this.registerEvent(states[i]);
		}

	},
	registerEvent : function(e, fun) {
		var a = e.split(">");
		if (a.length == 1) a = e.split("<");

		if (a.length > 1) {
		    for (var i = 0; i < a.length; i++) if (a[i].length > 0) this.addCallback(a[i]);
		} else this.addCallback(e);

		if (fun) this.base(e, fun);
	},
	addCallback : function(e, name) {
		switch (e) {
		    case "hover":
			this.low_addCallback("mouseover");
			this.low_addCallback("mouseout");
			this.addTransition("start", "mouseover", "hover");
			this.addTransition("hover", "mouseout", "start");
			break;
		    case "clicked":
			this.addTransition("start", "mousedown", "clicked");
			this.addTransition("hover", "mousedown", "clicked");
			this.addTransition("clicked", "mouseup", "start");
			this.addTransition("clicked", "mouseout", "start");
			this.low_addCallback("mousedown");
			this.low_addCallback("mouseup");
			break;
		    case "blur":
		    case "change":
		    case "click":
		    case "dblclick":
		    case "error":
		    case "focus":
		    case "load":
		    case "keydown":
		    case "keypress":
		    case "keyup":
		    case "reset":
		    case "select":
		    case "submit":
		    case "unload":
			this.low_addCallback(e);
		    	break;
		    default:
		    	this.addTransition("start", e, e);
			this.addTransition(e, "un"+e, "start");
		}
	},
	low_addCallback : function(e, name) {
		try {
		    this.node["on"+e] = UTIL.make_method(this, this.trigger, name||e);
		} catch (err) {
		    if (console && console.log) console.log("Setting the on%s event handler in %o failed.", e, this.node);
		}
	}
});
Widget.CSS = Widget.Base.extend({
	constructor : function(node, classes, actions) {
		if (!actions) actions = {};

		this.base(node, {}, actions);

		if (UTIL.arrayp(classes)) {
			for (var i = 0; i < classes.length; i++) {
				this.registerEvent(">"+classes[i], UTIL.make_method(window, UTIL.addClass, node, classes[i]));
				this.registerEvent(classes[i]+">", UTIL.make_method(window, UTIL.removeClass, node, classes[i]));
			}
		}
	}
});
Widget.Fader = Widget.Base.extend({
	constructor : function(node) {
		
		this.base(node);	
		this.registerEvent(">hide", UTIL.make_method(this, this.hide));
		this.registerEvent("hide>", UTIL.make_method(this, this.show));
	},
	hide : function() { UTIL.addClass(this.node, "hidden"); },
	show : function() { UTIL.removeClass(this.node, "hidden"); }
});
Widget.SlowFader = Widget.Fader.extend({
	constructor : function(node, params) {
		if (arguments.length < 2) params = {};
		this.T = params.effect_duration || 10000;
		this.fps = params.effect_fps || 15;
		this.stop = params.stop || 100;
		if (params.transform) this.transform = params.transform;
		this.ofade = UTIL.make_method(this, this.fade);
		this.base(node);
	},
	fade : function() {
		var percent;
		var now;

		if (!this.start) {
		    this.start = new Date();
		    percent = 0;
		} else {
		    now = new Date();
		    percent = UTIL.getDateOffset(this.start)/this.T;
		}

		if (percent > this.stop) {
		    	this.start = null;
			this.id = null;
			UTIL.addClass(this.node, "hidden");
			//TODO. would like to use ::hide();
			return;
		} else {
			if (this.transform) percent = this.transform(percent);
			percent = 100 - percent;
			if (UTIL.App.is_ie) {
			    this.node.style["-ms-filter"] = "progid:DXImageTransform.Microsoft.Alpha(Opacity="+percent+")";
			    this.node.style["filter"] = "alpha(opacity="+percentٌ+")";
			} else {
			    this.node.style["opacity"] = ""+percent/100.0;
			}
		}

		// we need to rethink. if rendering takes very long we should slow down a bit
		var delay = 1000/this.fps - UTIL.getDateOffset(now||this.start);
		if (delay < 20) delay = 20; // 50 fps is more than enough
		this.id = window.setTimeout(this.ofade, delay);
	},
	hide : function() {
		if (this.id) return; // we are already doing it
		this.fade();
	},
	show : function() {
		if (this.id) window.clearTimeout(this.id);
		if (UTIL.App.is_ie) {
		    delete this.node.style["-ms-filter"];
		    delete this.node.style["filter"];
		} else {
		    this.node.style["opacity"] = "";
		}
		this.base();
	}
});
Widget.Cycle = Base.extend({
	constructor : function() {
		this.items = [];
	},
	cycle : function(n) {
		if (this.items.length == 1) return;
		this.items[0].trigger("hide");
		if (n > 0) while (n-- > 0) this.items.push(this.items.shift());
		else if (n < 0) while (n++ > 0) this.items.unshift(this.items.pop());
		this.items[0].trigger("unhide");
	},
	addItem : function(widget) {
		this.items.push(widget);

		if (this.items.length == 1) {
			widget.trigger("unhide");
		} else {
			widget.trigger("hide");
		}
	},
	addButton : function(button, step) {
		button.registerEvent("click", UTIL.make_method(this, this.cycle, step||1));
	}
});
