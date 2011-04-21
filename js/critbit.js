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
    this.size = 1;
    this.C = [ null, null ];
    this.P = null;
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
    find_next : function(key) {
    },
    find_previous : function(key) {
    },
    insert : function(key) {
    },
    get_subtree : function(key) {
    },
    remove : function(key) {
    }
});
