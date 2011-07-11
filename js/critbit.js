var CritBit = {};
CritBit.Test = {};
CritBit.Test.Simple = UTIL.Test.extend({
    constructor : function(keys) {
	this.keys = keys;
	this.tree = new CritBit.Tree();
    },
    test_0_insert : function() {
	for (var i = 0; i < this.keys; i++) {
	    this.tree.insert(this.keys[i], i);
	    this.tree.check();
	}
	this.success();
    },
    test_1_lookup : function() {
	var t;
	for (var i = 0; i < this.keys; i++)
	    if ((t = this.tree.index(this.keys[i])) != i)
	    return this.error("lookup failed: %o gave %o. should be %o",
			      this.keys[i], t, i);
	this.success();
    }
});
CritBit.Test.RangeSet = UTIL.Test.extend({
    constructor : function(keys) {
	this.keys = keys.sort(function(a, b) {
	    if (a <= b && a >= b) return 0;
	    else if (a >= b) return 1;
	    else return -1;
	});
	this.n = keys.length >> 1;
    },
    test_0_merge : function() {
	var s = new CritBit.RangeSet();
	for (var i = 0; i < this.n; i++) {
	    s.insert(new CritBit.Range(this.keys[this.n-1-i],
				       this.keys[this.n+i]));
	    s.tree.check();
	    if (s.length() != 1)
		return this.error("%o suddenly has more than one range (has %d).\n",
				  s, s.length());
	}
	this.success();
    },
    test_1_merge : function() {
	var s = new CritBit.RangeSet();
	for (var i = 1; i+1 < this.keys.length-1; i+=2) {
	    s.insert(new CritBit.Range(this.keys[i],
				       this.keys[i+1]));
	    s.tree.check();
	    if (s.length() != (i+1)/2)
		return this.error("%o suddenly has wrong amount of ranges (%d vs %d).\n",
				  s, i, s.ranges().length);
	}
	s.insert(new CritBit.Range(this.keys[0], this.keys[this.keys.length-1]));

	if (s.length() != 1)
	    return this.error("%o suddenly has wrong amount of ranges.\n", s);
	this.success();
    }
});

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
	    if (key1 == key2) return new CritBit.Size(1,0);
	    return new CritBit.Size(0, 31 - CritBit.clz(key1 ^ key2));
	} else if (key1 instanceof Date) {
	    // remember to increase precision here until 2027
	    key1 = Math.floor(key1.getTime()/1000);
	    key2 = Math.floor(key2.getTime()/1000);
	    /*
	    UTIL.log("commong prefix: %o %o %o", key1, key2,
		     CritBit.count_prefix(key1, key2, start));
		     */
	    return CritBit.count_prefix(key1, key2, start);
	}
    } else if (UTIL.objectp(key1) && key1.count_prefix) {
	return key1.count_prefix(key2);
    } else if (UTIL.objectp(key2) && key2.count_prefix) {
	return key2.count_prefix(key1);
    }

    UTIL.error("Cannot count common prefix of %o and %o.", key1, key2);
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
    } else if (key instanceof Date) {
	return CritBit.get_bit(Math.floor(key.getTime()/1000), size);
    } else if (UTIL.objectp(key) && key.get_bit) {
	return key.get_bit(size);
    }
};
CritBit.sizeof = function(key) {
    if (UTIL.stringp(key)) {
	return new CritBit.Size(key.length, 0);
    } else if (UTIL.intp(key)) {
	return new CritBit.Size(1, 0);
    } else if (key instanceof Date) {
	return new CritBit.Size(1, 0);
    } else if (UTIL.objectp(key) && key.sizeof) {
	return key.sizeof();
    } UTIL.error("don't know the size of %o", key);
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
	var a = 0, b = 0;

	if (this.C[0]) a = this.C[0].depth();
	if (this.C[1]) b = this.C[1].depth();
	return 1 + Math.max(a, b);
    },
    first : function() {

	if (!this.has_value && this.C[0]) return this.C[0].first();

	//UTIL.log("first");
	return this;
    },
    last : function() {
	if (this.C[1]) return this.C[1].last();
	if (this.C[0]) return this.C[0].last();

	//UTIL.log("last");
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
	//UTIL.log("forward");
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
	//UTIL.trace();
	//UTIL.log("%o . backward()", this);
	if (this.P) {
	    //UTIL.log("have to go up again.");
	    var n = this;
	    while (n.P) {
		var bit = (n.P.C[1] == n);
		//UTIL.log("coming from bit %d\n", bit);
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
	    if (CritBit.get_bit(this.C[0].key, this.len) != 0)
		UTIL.error("has wrong bit: %o", this.C[0]);
	    this.C[0].check();
	}
	if (this.C[1]) {
	    if (this.C[0].P != this)
		UTIL.error("%o  :  wrong parent in 1", this);
	    if (CritBit.get_bit(this.C[1].key, this.len) != 1)
		UTIL.error("has wrong bit: %o", this.C[1]);
	    this.C[1].check();
	}
	if (this.P && this.P.len.ge(this.len)) {
	    UTIL.error("len not increasing at : %o", this);
	}
    },
    up_left : function() {
	//UTIL.log("up_left");
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
	//UTIL.log("%o->find_next_match(%o, %o, %o)", this, key, CritBit.sizeof(key), start);
	if (len.lt(start)) return null;
	if (len.eq(CritBit.sizeof(key)))
	    return (len.eq(this.len)) ? this.forward() : this.first();

	var bit = CritBit.get_bit(key, len);
	//UTIL.log("bit: %d", bit);

	if (len.eq(this.len)) {

	    //UTIL.log("bit: %d, %o", bit, this.C);
	    if (this.C[bit]) {
		var n = this.C[bit].find_next_match(key, len);
		if (n) return n;
	    }
	    if (!bit && this.C[1]) {
		//UTIL.log("%o foo", this);
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
	//UTIL.log("%o->find_prev_match(%o, %o, %o)", this, key, CritBit.sizeof(key), start);
	if (len.lt(start)) {
	    //UTIL.log("%o < %o", len, start);
	    return null;
	}
	if (len.eq(CritBit.sizeof(key)))
	    return this.backward();

	var bit = CritBit.get_bit(key, len);
	//UTIL.log("bit: %d", bit);

	if (len.eq(this.len)) {

	    //UTIL.log("bit: %d, %o", bit, this.C);
	    if (this.C[bit]) {
		var n = this.C[bit].find_prev_match(key, len);
		if (n) return n;
	    }
	    if (bit && this.C[0]) {
		//UTIL.log("%o foo", this);
		return this.C[0].last();
	    }
	    return this.backward();
	} else if (bit)
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
    check : function() {
	if (this.root) this.root.check();
    },
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
	    } else if (node.key == key
		    || (node.key >= key && node.key <= key)) {
		return node;
	    }

	    break;
	}

	return null;
    },
    last : function() {
	if (this.root) return this.root.last().key;
	return null;
    },
    first : function() {
	if (this.root) return this.root.first().key;
	return null;
    },
    nth : function(n) {
	if (this.root) {
	    var node = this.root.nth(n);
	    return node ? node.key : null;
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
	var n = this.low_index(key);

	if (n) {
//	    UTIL.log("removing : %o", n);
	    n.value = undefined;
	    n.has_value = false;
	    while (n) {
		if (!(--n.size)) {
		    if (!n.P) {
			this.root = null;
			return;
		    }
		    var bit = (n.P.C[1] === n ? 1 : 0);
		    n.P.C[bit] = null;
		}
		n = n.P;
	    }
	}
    },
    length : function() {
	return this.root ? this.root.size : 0;
    },
    foreach : function(fun, start, stop) {
	var node;

	if (!this.root) return;
	if (arguments.length > 2) {
	    node = this.ge(start);
	    if (arguments.length > 3) {
		stop = this.le(stop);
	    }
	}
	if (!node) node = this.root.first();
	//UTIL.log("start: "+ node);
	//UTIL.log("stop: "+ stop);

	if (!node) return;

	do {
	    if (fun(node.key, node.value) || node == stop) return;
	} while (node = node.forward());
    },
    backeach : function(fun, start, stop) {
	var node;

	if (!this.root) return;
	if (arguments.length > 2) {
	    node = this.le(start);
	    if (arguments.length > 3) {
		stop = this.ge(stop);
	    }
	}
	if (!node) node = this.root.last();
	//UTIL.log("start: "+ node);
	//UTIL.log("stop: "+ stop);

	if (!node) return;

	do {
	    if (fun(node.key, node.value) || node == stop) return;
	} while (node = node.backward());
    },
    find_best_match : function(key) {
	if (!this.root) return null;
	return this.root.find_best_match(key);
    },
    keys : function() {
	if (!this.root) return [];
	var ret = new Array(this.root.size);
	var i = 0;
	var node = this.root.first();
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
CritBit.Range = Base.extend({
    constructor : function(a, b, value) {
	this.a = a;
	this.b = b;
	if (arguments.length > 1) {
	    if (a >= b && !(a <= b))
		UTIL.error("Bad range. Ends before it starts.\n");
	    if (arguments.length > 2)
		this.value = value;
	}
    },
    overlaps : function(range) {
	return range.a <= this.b && range.b >= range.a;
//	return (Math.max(range.a, this.a) <= Math.min(range.b, this.b));
    },
    touches : function(range) {
	// this seems a bit odd, but we only have closed intervals right now
	return this.overlaps(range);
    },
    contains : function(i) {
	if (i instanceof CritBit.Range)
	    return this.a <= i.a && this.b >= i.b;
	return this.a <= i && this.b >= i;
    },
    length : function() {
	return this.b-this.a;
    },
    toString : function() {
	if (this.hasOwnProperty("value"))
	    return UTIL.sprintf("[%o..%o]<%o>", this.a, this.b, this.value);
	else
	    return UTIL.sprintf("[%o..%o]", this.a, this.b);
    }
});
CritBit.min = function(a, b) {
    if (a instanceof Date) {
	return a.getTime() > b.getTime() ? b : a;
    }
    return Math.min(a, b);
};
CritBit.max = function(a, b) {
    if (a instanceof Date) {
	return a.getTime() < b.getTime() ? b : a;
    }
    return Math.max(a, b);
};
CritBit.RangeSet = Base.extend({
    constructor : function(tree) {
	this.tree = tree || new CritBit.Tree();
    },
    index : function(key) {
	if (key instanceof CritBit.Range)
	    return this.contains(key);

	var next = this.tree.ge(key);
	if (!next) return undefined;
	return next.value.contains(key);
    },
    insert : function(range) {
	this.merge(range);
    },
    ranges : function() {
	return this.tree.values();
    },
    merge : function(range) {
	var a = [];
	//UTIL.log("merging %o", range);
	this.tree.foreach(function (s, i) {
	    //UTIL.log("%o touches %o == %o", i, range, i.touches(range));
	    if (!i.touches(range)) return true;
	    a.push(i);
	}, range.a);

	if (a.length) {
	    for (var i = 0; i < a.length; i++)
		this.tree.remove(a[i].b);
	    range = new CritBit.Range(CritBit.min(a[0].a, range.a),
				      CritBit.max(a[a.length-1].b, range.b));
	}
	this.tree.insert(range.b, range);
    },
    overlaps : function(range) {
	var n = this.tree.ge(range.a);
	if (n) return n.value.overlaps(range);
	return false;
    },
    contains : function(range) {
	var n = this.tree.ge(range.a);
	if (n) return n.value.contains(range);
	return false;
    },
    length : function() {
	return this.tree.length();
    }
});
CritBit.MultiRangeSet = Base.extend({
    constructor : function(tree, max_len) {
	this.tree = tree || new CritBit.Tree();
	this.max_len = (arguments.length < 2) ? 0 : max_len;
    },
    insert : function(range) {
	var v;
	this.max_len = Math.max(this.max_len, range.length());

	if (v = this.tree.low_index(range.a)) {
	    v.value.push(range);
	} else {
	    this.tree.insert(range.a, [ range ]);
	}
    },
    overlaps : function(range) {
	var ret = [];

	this.tree.backeach(function(start, i) {
	    if (range.a - i[0].a > this.max_len) {
		//UTIL.log("stopping early.");
		return true;
	    }
	    //UTIL.log("%o", i);
	    for (var j = 0; j < i.length; j++)
		if (range.overlaps(i[j])) ret.push(i[j]);
	}, range.b);
	return ret;
    },
    ranges : function() {
	var ret = [];
	var a = this.tree.values();
	for (var i = 0; i < a.length; i ++)
	    ret.concat(a[i]);
	return ret;
    },
    foreach : function(fun) {
	var a = this.ranges();
	for (var i = 0; i < a.length; i ++) {
	    if (fun(a[i])) return;
	}
    }
});
if (window.serialization) {
serialization.Range = serialization.Tuple.extend({
    constructor : function(type, vtype) {
	var m = [
	    "_range", CritBit.Range,
	    type, type
	];
	if (vtype) {
	    this.has_value = true;
	    m.push(vtype);
	}
	this.base.apply(this, m);
    },
    encode : function(range) {
	if (this.has_value)
	    return this.base([ range.a, range.b, range.value ]);
	else
	    return this.base([ range.a, range.b]);
    },
    toString : function() {
	return UTIL.sprintf("serialization.Range()");
    }
});
serialization.RangeSet = serialization.Array.extend({
    constructor : function(type) {
	this.base(type);
	this.type = "_rangeset";
    },
    decode : function(atom) {
	var a = this.base(atom);
	var t = new CritBit.RangeSet();
	for (var i = 0; i < a.length; i++)
	    t.insert(a[i]);
	return t;
    },
    encode : function(t) {
	return this.base(t.ranges());
    },
    can_encode : function(t) {
	return o instanceof CritBit.RangeSet || this.base(t);
    }
});
serialization.MultiRangeSet = serialization.RangeSet.extend({
    decode : function(atom) {
	var a = this.base(atom);
	var t = new CritBit.MultiRangeSet();
	for (var i = 0; i < a.length; i++)
	    t.insert(a[i]);
	return t;
    },
    can_encode : function(t) {
	return o instanceof CritBit.MultiRangeSet || this.base(t);
    }
});
}
