#define JSHIFT(x, y)	(((x)&0xffffffff)>>(y))
//#define JSHIFT(x, y)	((x < 0) ? ((((x)^Int.NATIVE_MIN) >> (y)) | (Int.NATIVE_MAX^(Int.NATIVE_MAX>>1)>>(y-1))) : ((x)>>(y)))
int amount_hashes(float p) {
    return (int)ceil(- Math.log2(p));
}

int table_mag(int n, float p) {
    int r = (int)floor(Math.log2(((float)n * amount_hashes(p))/log(2.0)))+1;
    return r;
}

int hash_length(int n, float p) {
    return table_mag(n, p) * amount_hashes(p);
}

class BitVector {
    int v;
    int length;


    int _sizeof() {
	return length;
    }

    void create(string|int|array(int) vector) {
	if (stringp(vector)) {
	    length = sizeof(vector) * 8;
	    if (String.width(vector) != 8)
		error("vector needs to be in binary");
	    sscanf(vector, "%-" + sizeof(vector) + "c", v);
	} else if (intp(vector)) {
	    length = vector;
	    v = 0;
	} else if (arrayp(vector)) {
	    v = 0;
	    foreach (reverse(vector);; int f) {
		v <<= 32;
		v |= f & 0xffffffff;
	    }
	    length = sizeof(vector) * 4 * 8;
	}
    }

    int `[](int n, int|void m) {
	if (!undefinedp(m)) {
	    int mask = (1 << (m-n+1)) - 1;
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
	    return sprintf("%-" + length + "c", v);
	error("cannot cast %O to %s.\n", this, type);
    }

    void fix_size() {
	length = v->size();
    }

    int get_int(int n, int len) {
	if (n + len < length) {
	    return this[n..n+len-1];
	}
	error("%d..%d is outside of 0..%d\n", n, n+len, length - 1);
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

class IntHash {
    int hash32shift(int i) {
	i = ~i + (i << 15); // i = (i << 15) - i - 1;
	i = i ^ JSHIFT(i, 12);
	i = i + (i << 2);
	i = i ^ JSHIFT(i, 4);
	i = i * 2057; // i = (i + (i << 3)) + (i << 11);
	i = i ^ JSHIFT(i, 16);
	return i & 0xffffffff;
    }

    int hashmap(int i) {
	i ^= JSHIFT(i, 20) ^ JSHIFT(i, 12);
	i ^= JSHIFT(i, 7) ^ JSHIFT(i, 4);
	return i & 0xffffffff;
    }

    int jenkins(int i) {
	i = (i+0x7ed55d16) + (i<<12);
	i = (i^0xc761c23c) ^ JSHIFT(i, 19);
	i = (i+0x165667b1) + (i<<5);
	i = (i+0xd3a2646c) ^ (i<<9);
	i = (i+0xfd7046c5) + (i<<3);
	i = (i^0xb55a4f09) ^ JSHIFT(i, 16);
	return i & 0xffffffff;
    }

    int block_bytes() {
	return 12;
    }

    BitVector hash(int i) {
	return BitVector(({ hashmap(i), hash32shift(i), jenkins(i) }));
    }
}
class Filter {
    BitVector table;
    int(0..1) inited = 0;
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

    void atom_init(void|int|BitVector v) {
	inited = 1;

	if (v && v != -1) {
	    int len = sizeof(v);
	    if (len & (len- 1)) {
		mag = len >> 3;
	    }
	    table = v;
	} else {
	    mag = table_mag(n, p);
	    int length = 1 << mag;
	    if (v == -1) table = BitVector(length);
	}
	n_hashes = amount_hashes(p);

	if (n_hashes * mag > hash->block_bytes() * 8) {
	    n_hashes = (int)floor((float)hash->block_bytes() * 8 / mag); 

	    if (n_hashes == 0)
		error("Hash has less bits than table size.");
	}
    }

    void create(object hash, int n, int removed, float p, void|BitVector v) {
	this_program::hash = hash;

	if (floatp(p)) {
	    werror("HELLO WITH FLOAT %O.\n", p);
	    this_program::n = n;
	    this_program::p = p;
	    this_program::removed = removed;

	    atom_init(v || -1);
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
	if (inited) {
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
	} else {
	    werror("Critical set: %O=%O\n", key, v);
	    return ::`[]=(key, v);
	}
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

class tFilter {
    inherit Serialization.Types.Struct;

    void create(program hash) {
	::create("_bloom", ([
		"n" : Serialization.Types.Int(),
		"p" : Serialization.Types.Float(),
		"removed" : Serialization.Types.Int(),
		"table" : tBitVector() ]), Function.curry(Filter)(hash()));
    }
}
