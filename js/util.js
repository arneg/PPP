UTIL = new Object();
UTIL.replace = function(reg, s, cb) {
	var res;
	var last = 0;
	var ret = "";
	var extra;

	if (arguments.length > 3) {
		extra = arguments.slice(4);	
	}

	while (null != (res = reg.exec(s))) {
		ret += s.substr(last, reg.lastIndex - res.length - last) + (extra ? cb.apply(null, [res].concat(extra)) : cb(res));
		last = reg.lastIndex + res.length + 1;
	}

	if (last < s.length) {
		ret += s.substr(last);
	}

	return ret;
}
