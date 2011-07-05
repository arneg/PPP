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
		    return new CritBit.Size(i, 15 - CritBit.clz(key1.charCodeAt(i) ^ key2.charCodeAt(i)));
		}
	    }

	    return CritBit.sizeof(key1);
	} else if (UTIL.intp(key1)) {
	    if (key1 == key2) return 32;
	    return new CritBit.Size(0, 31 - CritBit.clz(key1 ^ key2));
	}
    }

    throw("Strange types mismatch.");
};
CritBit.get_bit = function(key, size) {
    if (!(size instanceof CritBit.Size)) UTIL.error("wrong size.");
    if (UTIL.stringp(key)) {
	if (size.chars >= key.length || size.bits > 16) {
	    UTIL.error("index out of bounds.");
	}
	return !!(key.charCodeAt(size.chars) & (1 << (15-size.bits))) ? 1 : 0;
    } else if (UTIL.intp(key)) {
	if (size.chars || size.bits > 31) {
	    UTIL.error("index out of bounds.");
	}

	return !!(key & (1 << (31-size.bits))) ? 1 : 0;
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
    this.size = this.has_value ? 1 : 0;
    this.C = [ null, null ];
    this.P = null;
};
CritBit.Node.prototype = {
    toString : function() {
	return UTIL.sprintf("Node(%o, len(%d,%d), %o)", this.key,
			    this.len.chars, this.len.bits, this.has_value);
    },
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
	UTIL.log("first");
	var node = this.root;

	if (!this.has_value && this.C[0]) return this.C[0].first();

	return this;
    },
    last : function() {
	UTIL.log("last");

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

	if (sv && this.has_value) return this;
	
	if (this.P) return this.P.up(true);
	return null;
    },
    forward : function() {
	UTIL.log("forward");
	if (this.C[0]) {
	    //UTIL.log("traversing down left");
	    return this.C[0].first();
	}
	if (this.C[1]) {
	    //UTIL.log("traversing down right");
	    return this.C[1].first();
	}
	return this.up_left();
    },
    backward : function() {
	if (this.P) {
	    //UTIL.log("have to go up again.");
	    var n = this;
	    while (n.P) {
		var bit = (n.P.C[1] == n);
		if (bit && n.P.C[0])
		    return n.P.C[0].last();
		n = n.P;
		if (n.has_value) return n;
	    }
	}
	return null;
    },
    check : function() {
	if (this.C[0]) {
	    if (this.C[0].P != this)
		UTIL.error("%o  :  wrong parent in 0", this);
	    this.C[0].check();
	}
	if (this.C[1]) {
	    if (this.C[0].P != this)
		UTIL.error("%o  :  wrong parent in 1", this);
	    this.C[0].check();
	}
    },
    up_left : function() {
	UTIL.log("up_left");
	//UTIL.log("going up");
	var n = this;
	while (n.P) {
	    //UTIL.log("%o in %o", n, n.P.C);
	    if (n.P.C[0] === n && n.P.C[1])
		return n.P.C[1].first();
	    n = n.P;
	}
	//UTIL.log("hit root %o", n);
	return null;
    },
    find_best_match : function(key, start) {
	if (!start) start = new CritBit.Size(0,0);
	var len = CritBit.count_prefix(key, this.key);
	len = len.min(this.len).min(CritBit.sizeof(key));
	//UTIL.log("prefix(%o, %o) == %o", key, this.key, len);
	if (len.le(start)) return null;
	if (len.eq(this.len)) {
	    if (len.eq(CritBit.sizeof(key))) {
		return this;
	    }

	    var bit = CritBit.get_bit(key, this.len);
	    //UTIL.log("bit: %d, %o", bit, this.C);
	    if (this.C[bit]) {
		var n = this.C[bit].find_best_match(key, len);
		if (n) return n;
	    }
	    return this;
	}
	return null;
    },
    // TODO: these two need to be rewritten. they dont work like this
    //
    find_next_match : function(key, start) {
	if (!start) start = new CritBit.Size(0,0);
	var len = CritBit.count_prefix(key, this.key);
	len = len.min(this.len).min(CritBit.sizeof(key));
	//UTIL.log("prefix(%o, %o) == %o", key, this.key, len);
	UTIL.log("%o->find_next_match(%o, %o, %o)", this, key, CritBit.sizeof(key), start);
	if (len.lt(start)) return null;
	if (len.eq(CritBit.sizeof(key)))
	    return (len.eq(this.len)) ? this.forward() : this.first();

	var bit = CritBit.get_bit(key, len);
	UTIL.log("bit: %d", bit);
	
	if (len.eq(this.len)) {

	    //UTIL.log("bit: %d, %o", bit, this.C);
	    if (this.C[bit]) {
		var n = this.C[bit].find_next_match(key, len);
		if (n) return n;
	    }
	    if (!bit && this.C[1]) {
		UTIL.log("%o foo", this);
		return this.C[1].first();
	    }
	    return this.up_left();
	}

	return this.up_left();
    },
    find_prev_match : function(key, start) {
	if (!start) start = new CritBit.Size(0,0);
	var len = CritBit.count_prefix(key, this.key);
	len = len.min(this.len).min(CritBit.sizeof(key));
	//UTIL.log("prefix(%o, %o) == %o", key, this.key, len);
	UTIL.log("%o->find_prev_match(%o, %o, %o)", this, key, CritBit.sizeof(key), start);
	if (len.lt(start)) return null;
	if (len.eq(CritBit.sizeof(key)))
	    return this.backward();

	var bit = CritBit.get_bit(key, len);
	UTIL.log("bit: %d", bit);
	
	if (len.eq(this.len)) {

	    //UTIL.log("bit: %d, %o", bit, this.C);
	    if (this.C[bit]) {
		var n = this.C[bit].find_prev_match(key, len);
		if (n) return n;
	    }
	    if (bit && this.C[0]) {
		UTIL.log("%o foo", this);
		return this.C[0].last();
	    }
	    return this.backward();
	} else if (!bit)
	    return this.last();

	return this.backward();
    },
    insert : function(node) {
	if (!node.has_value) return this;

	var bit;
	var len = CritBit.count_prefix(node.key, this.key);
	len = len.min(this.len).min(node.len);
	//UTIL.log("prefix(%o, %o) == %o", node.key, this.key, len);
	if (len.eq(this.len)) {
	    // overwriting
	    if (len.eq(node.len)) {
		this.value = node.value;
		// we overwrite the key, otherwise it might end up
		// being a substring
		this.key = node.key;
		if (!this.has_value) this.size ++;
		this.has_value = true;
		return this;
	    }
	    // traverse
	    bit = CritBit.get_bit(node.key, this.len);
	    //UTIL.log("bit: %d", bit);

	    if (this.C[bit]) {
		var oldsize = this.C[bit].size;
		this.child(bit, this.C[bit].insert(node));
		if (this.C[bit].size > oldsize) this.size++;
		return this;
	    } else {
		//UTIL.log("setting new node %o", node);
		this.child(bit, node);
		this.size++;
	    }

	    return this;
	} 

	bit = CritBit.get_bit(this.key, len);

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
	    /*
	    UTIL.log("creating new split node %o", n);
	    UTIL.log("%o %o", this.P, node.P);
	    */
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
	if (node && node.has_value) return node.value;
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
    ge : function(key) {
	if (!this.root) return null;
	var node = this.low_index(key);
	if (node) return node;
	return this.root.find_next_match(key);
    },
    gt : function(key) {
	if (!this.root) return null;
	var node = this.low_index(key);
	if (node) return node.forward();
	return this.root.find_next_match(key);
    },
    next : function(key) {
	var node = this.gt(key);
	return node ? node.key : null;
    },
    lt : function(key) {
	if (!this.root) return null
	var node = this.low_index(key);
	if (node) return node.backward();
	return this.root.find_prev_match(key);
    },
    le : function(key) {
	if (!this.root) return null
	var node = this.low_index(key);
	if (node) return node;
	return this.root.find_prev_match(key);
    },
    previous : function(key) {
	var node = this.lt(key);
	return node ? node.key : null;
    },
    insert : function(key, value) {
	this.root = this.root ? this.root.insert(new CritBit.Node(key, value)) : new CritBit.Node(key, value);
    },
    get_subtree : function(key) {
    },
    remove : function(key) {
    },
    length : function() {
	return this.root ? this.root.size : 0;
    },
    foreach : function(fun, start, stop) {
	var node;

	if (!this.root) return;
	if (arguments.length > 1) {
	    node = this.ge(start);
	    if (arguments.length > 2) {
		stop = this.le(stop);
	    } 
	} else node = this.root.first();
	UTIL.log("start: "+ node);
	UTIL.log("stop: "+ stop);

	if (!node) return;

	do {
	    if (fun(node.key, node.value) || node == stop) return;
	} while (node = node.forward());
    },
    find_best_match : function(key) {
	if (!this.root) return null;
	return this.root.find_best_match(key);
    },
    keys : function() {
	if (!this.root) return [];
	var ret = new Array(this.root.size);
	var i = 0;
	var node = this.root.first()
	do {
	    ret[i++] = node.key;
	} while(node = node.forward());
	return ret;
    },
    values : function() {
	if (!this.root) return [];
	var ret = new Array(this.root.size);
	var i = 0;
	var node = this.root.first();
	do {
	    ret[i++] = node.value;
	} while(node = node.forward());
	return ret;
    }
});
