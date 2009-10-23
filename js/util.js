/**
 * Some helpful utility functions.
 * @namespace
 */
UTIL = new Object();
/**
 * Flexible RegExp-based replace function. Calls a callback for every match and replaced it by the returned string.
 * @param {Object} reg RegExp Object to be used.
 * @param {String} s String to perform the replace on.
 * @param {Function} cb Callback to be called for every match. Parameters to the callback will be the result returned by the call to RegExp.exec and possible extra arguments that were passed to replace.
 * @returns The resulting string.
 */
UTIL.replace = function(reg, s, cb) {
	var res;
	var last = 0;
	var ret = "";
	var extra;

	if (arguments.length > 3) {
		extra = new Array();
		for (var i = 3; i < arguments.length; i++) extra[i-3] = arguments[i];
	}

	while (null != (res = reg.exec(s))) {
		ret += s.substr(last, reg.lastIndex - res[0].length - last); 
		ret += (extra ? cb.apply(null, [res].concat(extra)) : cb(res));
		last = reg.lastIndex;
	}

	if (last < s.length) {
		ret += s.substr(last);
	}

	return ret;
}
UTIL.split_replace = function(reg, s, cb) {
	var res;
	var last = 0;
	var ret = new Array();
	var extra;

	if (arguments.length > 3) {
		extra = new Array();
		for (var i = 3; i < arguments.length; i++) extra[i-3] = arguments[i];
	}

	while (null != (res = reg.exec(s))) {
		ret.push(s.substr(last, reg.lastIndex - res[0].length - last));
		ret.push(extra ? cb.apply(null, [res].concat(extra)) : cb(res));
		last = reg.lastIndex;
	}

	if (last < s.length) {
		ret.push(s.substr(last));
	}

	return ret;
}
UTIL.has_prefix = function(s, n) {
	if (s.length < n.length) return false;
	return (n == s.substr(0, n.length));
}
UTIL.has_suffix = function(s, n) {
	if (s.length < n.length) return false;
	return (n == s.substr(s.length-n.length, n.length));
}
UTIL.search_array = function(a, n) {
	for (var i = 0; i < a.length; i++) {
		if (n == a[i]) return i;
	}

	return -1;
}
UTIL.replaceClass = function(o, cl1, cl2) {
	var classes = o.className.split(' ');
	var i = UTIL.search_array(classes, cl1);
	var j = UTIL.search_array(classes, cl2);

	if (i == -1 && j == -1) {
		if (cl2) classes.push(cl2);
	} else if (i == -1) {
		return;
	} else if (j == -1 && cl2) {
		classes[i] = cl2;
	} else {
		classes.splice(i, 1);
	}
	o.className = classes.join(" ");
}
UTIL.addClass = function(o, cl) {
	var classes = o.className.split(' ');
	var i = UTIL.search_array(classes, cl);

	if (i == -1) {
		classes.push(cl);
		o.className = classes.join(" ");
	}
}
UTIL.hasClass = function(o, cl) {
	var classes = o.className.split(' ');
	return (-1 != UTIL.search_array(classes, cl));
}
