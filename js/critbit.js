var CritBit = {};
CritBit.Size = Base.extend({
    constructor : function(chars, bits) {
	this.chars = chars;
	this.bits = bits;
    },
    eq : function(b) {
	return this.chars == b.chars && this.bits == b.bits;
    },
    lt : function(b) {
	return this.chars < b.chars || (this.chars == b.chars && this.bits < b.bits);
    },
    le : function(b) {
	return this.eq(b) || this.lt(b);
    },
    min : function(b) {
	if (b.chars < this.chars || (b.chars == this.chars && b.bits == this.bits)) {
	    return b;
	} else return this;
    },
    max : function(b) {
	if (b.chars < this.chars || (b.chars == this.chars && b.bits == this.bits)) {
	    return this;
	} else return b;
    }
});
CritBit.clz = function(x) {
    return Math.floor(Math.log(x)/Math.LN2);
};
CritBit.count_prefix = function(key1, key2, start) {
    if (typeof(key1) == typeof(key2)) {
	if (UTIL.stringp(key1)) {
	    if (key1 == key2) return new CritBit.Size(key1.length, 0);
	    if (key1.length > key2.length) {
		var t = key1;
		key1 = key2;
		key2 = t;
	    }
	    for (var i = start.chars; i < key1.length; i++) {
		if (key1.charCodeAt(i) != key2.charCodeAt(i)) {
		    return new CritBit.Size(i, CritBit.clz(key1.charCodeAt(i) ^ key2.charCodeAt(i)));
		}
	    }

	    return CritBit.sizeof(key1);
	} else if (UTIL.intp(key1)) {
	    if (key1 == key2) return 32;
	    return new CritBit.Size(0, CritBit.clz(key1 ^ key2));
	}
    }

    throw("Strange types mismatch.");
};
CritBit.get_bit = function(key, size) {
    if (UTIL.stringp(key)) {
	if (size.chars >= key.length || size.bits > 31) {
	    throw("index out of bounds.");
	}
	return !!(key.charCodeAt(size.chars) & (1 << size.bits));
    } else if (UTIL.intp(key)) {
	if (size.chars || size.bits > 31) {
	    throw("index out of bounds.");
	}

	return !!(key & (1 << size.bits));
    }
};
CritBit.sizeof = function(key) {
    if (UTIL.stringp(key)) {
	return new CritBit.Size(key.length, 0);
    } else if (UTIL.intp(key)) {
	return new CritBit.Size(0, 32);
    }
};
CritBit.Node = function(key, value) {
    this.key = key;
    this.len = CritBit.sizeof(key);
    this.value = value;
    this.has_value = (arguments.length >= 2);
    this.size = 1;
    this.C = [ null, null ];
    this.P = null;
};
CritBit.Node.prototype = {
    depth : function() {
	var a, b, len = 1;

	if (this.C[0]) a = this.C[0].depth();
	if (this.C[1]) a = this.C[1].depth();
	return 1 + ((a > b) ? a : b);
    },
    first : function() {
	var node = this.root;

	if (!this.has_value && this.C[0]) return this.C[0].first();

	return this;
    },
    last : function() {

	if (this.C[1]) return this.C[1].last();
	if (this.C[0]) return this.C[0].last();

	return this;
    },
    nth : function(n) {
	var ln;
	if (n > this.size-1) return null;
	if (n <= 0 && this.has_value) return this;
	if (this.has_value) n --;
	if (this.C[0]) {
	    ln = this.C[0].size;
	    if (n < ln) {
		return this.C[0].nth(n);
	    }
	    n -= ln;
	}
	return this.C[1].nth(n-ln);
    },
    up : function(sv) {

	if (sv && this.value) return this;
	
	if (this.parent) return this.parent.up(true);
	return null;
    },
    forward : function() {
	if (this.C[0]) return this.C[0].first();
	if (this.C[1]) return this.C[0].first();
	else if (this.parent) {
	    var n = this;
	    while (n.parent) {
		var bit = (n.parent.C[1] == n);
		if (!bit && n.parent.C[1])
		    return n.parent.C[1].first();
		n = n.parent;
	    }
	}
	return null;
    },
    insert : function(node) {
	if (!node.has_value) return 0;

	if (node.key == this.key) {
	    this.value = node.value;
	    var r = this.has_value;
	    this.has_value = true;
	    return r ? 0 : 1;
	}


    },
};
CritBit.Tree = Base.extend({
    constructor : function() {
	this.root = null;
    },
    index : function(key) {
	var node = this.root;
	var len = CritBit.sizeof(key);

	while (node) {
	    if (node.size.lt(len)) {
		var bit = CritBit.get_bit(key, node.size);

		node = node.C[bit];
		continue;
	    } else if (node.key == key) {
		return node.value;
	    }

	    break;
	}

	return null;
    },
    last : function() {
	if (this.root) return this.root.last().value;
	return null;
    },
    first : function() {
	if (this.root) return this.root.first().value;
	return null;
    },
    nth : function(n) {
	if (this.root) {
	    var node = this.root.nth(n);
	    return node ? node.value : null;
	}
	return null;
    },
    find_next : function(key) {
    },
    find_previous : function(key) {
    },
    insert : function(key, value) {
    },
    get_subtree : function(key) {
    },
    remove : function(key) {
    }
});
