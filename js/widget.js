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
		//console.log("%o->trigger(%s)", this.node, e);
		if (!ev && UTIL.App.is_ie && window.event) ev = window.event;
		//console.log("%o.trigger(%s)", this, e);
		if (this.t[this.state].hasOwnProperty(e)) {
			var nstate = this.t[this.state][e];
			this.callEvent(this.state+">"+nstate, [ e, ev, this.state, nstate ]);
			this.callEvent(this.state+">", [e, ev, this.state, nstate ]);
			this.callEvent(">"+nstate, [e, ev, this.state, nstate ]);
			this.state = nstate;
		}
		this.callEvent(e, this.state, [e, ev]);
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
			case "start":
		    default: return;
		}
	},
	low_addCallback : function(e, name) {
		try {
		    this.node["on"+e] = UTIL.make_method(this, this.trigger, name||e);
		} catch (err) {
		    //if (console && console.log) console.log("Setting the on%s event handler in %o failed.", e, this.node);
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
Widget.Fx = {};
Widget.Fx.CSS = Widget.Base.extend({
	constructor : function(node, states, transitions, fade_properties) {
		this.css_states = states;
		this.current_css_state = states.start;
		this.fade_properties = fade_properties || { duration : 3000 };
		this.fade_object = null;
		this.onDone = {};
		this.onStart = {};
		var actions = {};

		for (var i in transitions) if (states.hasOwnProperty(i)) {
			for (var e in transitions[i]) if (transitions[i].hasOwnProperty(e)) {
				var from_state = i;
				var to_state = transitions[i][e];
				var from = states[i];
				var	to = states[transitions[i][e]]


				if (to) {
					if (to.onDone) {
						this.onDone[to_state] = to["onDone"];
					}

					if (to.onStart) {
						this.onStart[to_state] = to.onStart;
					}

					actions[from_state+">"+to_state] = UTIL.make_method(this, this.fade, to_state, to);
				}
			}
		}
		this.base(node, transitions, actions);
	},
	fade : function(to_state, to) {
		if (this.fade_object) {
			this.fade_object.stop();
			this.fade_object = null;
		}

		//console.log("fading %o to %o with %o", this.node, to, this.fade_properties);
		//this.fade_object = Uize.Fx.fadeStyle(this.node, null, to, this.fade_properties);
		//this.fade_object = Uize.Fx.fadeStyle(this.node, null, to, this.fade_properties.duration);
		if (this.onDone[to_state]) this.fade_object.wire("Done", UTIL.make_method(this, this.onDone[to_state], this.node));
		if (this.onStart[to_state]) UTIL.make_method(this, this.onStart[to_state], this.node)();
		//this.fade_object.start();
	}
});
Widget.SlowFader = Widget.Fader.extend({
	constructor : function(node, params) {
		if (arguments.length < 2) params = {};
		this.hiding = false;
		this.hide_duration = params.hide_duration || params.duration || 2000;
		this.show_duration = params.show_duration || params.duration || 2000;
		this.fps = params.effect_fps || 20;
		this.hide_max = params.hide_max || params.max || 100;
		this.show_max = params.show_max || params.max || 100;
		this.hide_transform = params.hide_transform || params.transform;
		this.show_transform = params.show_transform || params.transform;
		this.base(node);
	},
	fade : function(transform, start, duration, max) {
		var percent;
		var npercent;
		var now;
		
		if (!start) {
		    start = new Date();
		    percent = 0;
		} else {
		    now = new Date();
		    percent = UTIL.getDateOffset(start, now)/duration * 100;
		}

		if (percent < max) {
			if (transform && UTIL.intp(transform) || UTIL.floatp(transform)) {
				if (transform < 0) npercent = 100 + transform*percent;
				else npercent = transform * percent;
			} else if (UTIL.functionp(transform)) npercent = transform(percent);
			else npercent = percent;
		}

		if (percent >= max || npercent >= max) {
			this.id = null;

			if (this.hiding) {
				this.node.parentNode.style.minHeight = this.node.offsetHeight + "px";
				this.node.parentNode.style.minWidth = this.node.offsetWidth + "px";
				UTIL.addClass(this.node, "hidden");
			}

			if (UTIL.App.is_ie) {
				this.node.style["-ms-filter"] = "";
				this.node.style["filter"] = "";
			} else {
				this.node.style["opacity"] = "";
			}

			//TODO. would like to use ::hide();
			return;
		} 
		//console.log("%o s of %o s\t%s.%s(%o)\t%o", now ? UTIL.getDateOffset(start, now)/1000 : 0.0, duration/1000, this.node.id, this.hiding ? "hide" : "show" , percent, npercent);

		percent = npercent;
		
		if (this.hiding) percent = 100 - percent;

		if (percent > 0) {
			if (!this.hiding) {
				UTIL.removeClass(this.node, "hidden");
				this.node.parentNode.style.minHeight = "";
				this.node.parentNode.style.minWidth = "";
			}
			if (UTIL.App.is_ie) {
				this.node.style["-ms-filter"] = "progid:DXImageTransform.Microsoft.Alpha(Opacity="+percent+")";
				this.node.style["filter"] = "alpha(opacity="+percentٌ+")";
			} else {
				this.node.style["opacity"] = ""+percent/100.0;
			}
		}

		// we need to rethink. if rendering takes very long we should slow down a bit
		var delay = 1000/this.fps - UTIL.getDateOffset(now||start);
		if (delay < 25) delay = 25; // 40 fps is more than enough
		this.id = window.setTimeout(UTIL.make_method(this, this.fade, transform, start, duration, max), delay);
	},
	hide : function() {
		if (this.id) {
			if (this.hiding) return;

			window.clearTimeout(this.id);
		}
		this.hiding = true;
		this.fade(this.hide_transform, 0, this.hide_duration, this.hide_max);
	},
	show : function() {
		if (this.id) {
			if (!this.hiding) return;

			window.clearTimeout(this.id);
		}
		this.hiding = false;
		this.fade(this.show_transform, 0, this.show_duration, this.show_max);
	}
});
Widget.Cycle = Base.extend({
	constructor : function() {
		this.items = [];
	},
	cycle : function(n) {
		if (arguments.length == 0) n = 1;
		if (this.items.length == 1) return;
		var old = this.items[0];
		if (n > 0) while (n-- > 0) this.items.push(this.items.shift());
		else if (n < 0) while (n++ > 0) this.items.unshift(this.items.pop());
		var t = this.items[0];

		old.trigger("hide");
		t.trigger("unhide");
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
