UTIL.Base64.Test = UTIL.Test.extend({
    constructor : function(n) {
	this.s = UTIL.nchars(255^(1<<3), n);
    },
    test_0_encode : function() {
	this.enc = UTIL.Base64.encode(this.s);
	this.success();
    },
    test_1_decode : function() {
	this.dec = UTIL.Base64.decode(this.enc);
	this.success();
    },
    test_2_validity : function() {
	if (this.dec != this.s) {
	    this.error("Something is fishy in the encoding of the 64 (len %d vs %d).", this.s.length, this.dec.length);
	    return;
	}
	this.success();
    }
});
