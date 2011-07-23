int amount_hashes(float p) {
    return (int)ceil(- Math.log2(p));
}

int table_mag(int n, float p) {
    return (int)floor(Math.log2((float)n * amount_hashes(p)));
}

int hash_length(int n, float p) {
    return table_mag(n, p) * amount_hashes(p);
}

class BitVector {
    int v;
    int length;


    int _sizeof() {
	return length * 8;
    }

    void create(string|int|array(int) vector) {
	if (stringp(vector)) {
	    length = sizeof(vector);
	    if (String.width(vector) != 8)
		error("vector needs to be in binary");
	    sscanf(vector, "%" + sizeof(vector) + "c", v);
	} else if (intp(vector)) {
	    length = vector;
	    v = 0;
	} else if (arrayp(vector)) {
	    v = 0;
	    foreach (vector;; int f) {
		v <<= 32;
		v |= f & 0xffffffff;
	    }
	    length = sizeof(vector) * 4;
	}
    }

    int `[](int n, int|void m) {
	if (!zero_type(m)) {
	    int mask = (1 << (m-n)) - 1;
	    return ((v>>n)&mask);
	}
	return (v & (1 << n)) ? 1 : 0;
    }

    int(0..1) `[]=(int n, mixed v) {
	if (this[n] != !!v) this_program::v ^= 1 << n;
	return !!v;
    }

    mixed cast(string type) {
	if (type == "array") {
	    return ({ (string)this, sizeof(this) });
	} else if (type == "string") 
	    return sprintf("%" + length + "c", v);
	error("cannot cast %O to %s.\n", this, type);
    }

    void fix_size() {
	length = (int)ceil(v->size() / 8.0);
    }

    int get_int(int n, int len) {
	if (n + len < length) {
	    return this[n..n+len-1];
	}
	error("Not in there!");
    }
}

class SHA256 {
    int block_bytes() {
	return 64;
    }

    BitVector hash(string s) {
	return BitVector(Crypto.SHA256()->hash(s));
    }
}

class Filter {
    BitVector table;
    int n;
    float p;
    protected int mag;
    protected int n_hashes;
    protected object hash;
    int removed = 0;
    protected int size = 0;

    int _sizeof() {
	return size - removed;
    }

    void create(object hash, int n, int removed, float p, void|BitVector v) {
	this_program::hash = hash;
	this_program::n = n;
	this_program::p = p;
	this_program::removed = removed;
	if (v) {
	    if (v->length & (v->length - 1)) {
		mag = v->length >> 3;
	    }
	    table = v;
	} else {
	    mag = table_mag(n, p);
	    int length = 1 << mag;
	    table = BitVector(length);
	}
	n_hashes = amount_hashes(p);

	if (n_hashes * mag > hash->block_bytes() * 8) {
	    n_hashes = (int)floor(hash->block_bytes() * 8 / mag); 

	    if (n_hashes == 0)
		error("Hash has less bits than table size.");
	}
    }

    function prepare(mixed key) {
	BitVector h = hash->hash(key);

	mixed _(object filter) {
	    return filter->hash_index(h);
	};

	return _;
    }

    int(0..1) hash_index(BitVector h) {
	for (int i = 0; i < n_hashes; i++) {
	    if (!table[h->get_int(i*mag, mag)]) {
		return UNDEFINED;
	    }
	}
	return 1;
    }

    // this is upper bound for probability. it cannot be worse
    float prob() {
	if (removed >= size) return 1.0;
	if (size == 0) return 0.0;
	return min(1.0, removed/(float)size 
	    + pow((1 - exp(-(float)n_hashes * size / (1<<mag))), n_hashes));
    }

    mixed `[](mixed key) {
	return hash_index(hash->hash(key));
    }

    mixed `[]=(mixed key, mixed v) {
	if (!v) {
	    if (this[key]) removed ++;
	    return UNDEFINED;
	}
	size++;
	BitVector h = hash->hash(key);
	for (int i = 0; i < n_hashes; i++) {
	    table[h->get_int(i*mag, mag)] = 1;
	}
	return 1;
    }

    mixed cast(string type) {
	if (type == "array") {
	    return ({ n, p, removed, table });
	}
    }
}

class tBitVector {
    inherit Serialization.Types.Tuple;

    void create() {
	object t = Serialization.Types.Binary();
	::create("_bitvector", BitVector, t, Serialization.Types.Int());
    }

    Serialization.Atom encode(BitVector o) {
	return ::encode(({ (string)o, sizeof(o) }));
    }
}

class tBloomFilter {
    inherit Serialization.Types.Tuple;

    void create(program hash) {
	::create("_bloomfilter", Function.curry(Filter)(hash), Serialization.Types.Int(), Serialization.Types.Int(), Serialization.Types.Float(), tBitVector());
    }
}
