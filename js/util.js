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
