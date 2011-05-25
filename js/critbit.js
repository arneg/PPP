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
    },
    toString : function() {
	return "S("+this.chars+":"+this.bits+")";
    }
});
CritBit.clz = function(x) {
    return Math.floor(Math.log(x)/Math.LN2);
};
CritBit.count_prefix = function(key1, key2, start) {
    if (!start) start = new CritBit.Size(0,0);
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
    if (!(size instanceof CritBit.Size)) UTIL.error("wrong size.");
    if (UTIL.stringp(key)) {
	if (size.chars >= key.length || size.bits > 31) {
	    throw("index out of bounds.");
	}
	return !!(key.charCodeAt(size.chars) & (1 << size.bits)) ? 1 : 0;
    } else if (UTIL.intp(key)) {
	if (size.chars || size.bits > 31) {
	    throw("index out of bounds.");
	}

	return !!(key & (1 << size.bits)) ? 1 : 0;
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
    child : function(bit, node) {
	if (arguments.length >= 2) {
	    this.C[(!bit) ? 0 : 1] = node;
	    node.P = this;
	} else return this.C[(!bit) ? 0 : 1];
    },
    depth : function() {
	var a = 0, b = 0, len = 1;

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
	
	if (this.P) return this.P.up(true);
	return null;
    },
    forward : function() {
	if (this.C[0]) {
	    UTIL.log("traversing down left");
	    return this.C[0].first();
	}
	if (this.C[1]) {
	    UTIL.log("traversing down left");
	    return this.C[0].first();
	}
	if (this.P) {
	    UTIL.log("have to go up again.");
	    var n = this;
	    while (n.P) {
		var bit = (n.P.C[1] == n);
		UTIL.log();
		if (!bit && n.P.C[1])
		    return n.P.C[1].first();
		n = n.P;
	    }
	}
	return null;
    },
    insert : function(node) {
	if (!node.has_value) return this;

	var len = CritBit.count_prefix(node.key, this.key);
	UTIL.log("prefix(%o, %o) == %o", node.key, this.key, len);
	if (len.eq(this.len)) {
	    // overwriting
	    if (len.eq(node.len)) {
		this.value = node.value;
		// we overwrite the key, otherwise it might end up
		// being a substring
		this.key = node.key;
		var r = this.has_value;
		this.has_value = true;
		if (!r)
		    this.size ++;
		return this;
	    }
	    // traverse
	    var bit = CritBit.get_bit(node.key, this.len);
	    if (this.C[bit]) {
		var oldsize = this.C[bit].size;
		this.C[bit] = this.C[bit].insert(node);
		if (this.C[bit].size > oldsize) this.size++;
		return this;
	    } else {
		this.child(bit, node);
		this.size++;
	    }
	    return this;
	} 

	var bit = CritBit.get_bit(this.key, len);

	if (len.eq(node.len)) { // is substring
	    node.child(bit, this);
	    node.size += this.size;
	    return node;
	} else { // none is prefix of the other.
	    var n = new CritBit.Node(node.key);
	    n.len = len;
	    n.size = this.size + node.size;
	    n.child(bit, this);
	    n.child(!bit, node);
	    UTIL.log("creating new split node %o", n);
	    return n;
	}
    }
};
CritBit.Tree = Base.extend({
    constructor : function() {
	this.root = null;
    },
    index : function(key) {
	var node = this.low_index(key);
	if (node) return node.value;
	return null;
    },
    low_index : function(key) {
	var node = this.root;
	var len = CritBit.sizeof(key);

	while (node) {
	    if (node.len.lt(len)) {
		var bit = CritBit.get_bit(key, node.len);

		node = node.C[bit];
		continue;
	    } else if (node.key == key) {
		return node;
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
    next : function(key) {
	if (this.root) {
	    var node = this.low_index(key);
	    if (node) {
		node = node.forward();
		return !!node ? node.key : null;
	    }

	    node = this.root.next(key);
	    return !!node ? node.key : null;
	}
	return null;
    },
    previous : function(key) {
    },
    insert : function(key, value) {
	if (!this.root) {
	    this.root = new CritBit.Node(key, value);
	    return;
	}

	this.root = this.root.insert(new CritBit.Node(key, value));
    },
    get_subtree : function(key) {
    },
    remove : function(key) {
    },
    length : function() {
	return this.root ? this.root.size : 0;
    },
    foreach : function(fun) {
	var node = this.root;

	if (node.has_value && 
	    fun(node.key, node.value)) return;

	while (node = node.forward()) {
	    if (fun(node.key, node.value)) return;
	}
    }
});
