UTIL = new Object();
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
