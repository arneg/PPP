UTF8.Test = {
    lencode : function(s) {
	return unescape( encodeURIComponent( s ) );
    },
    ldecode : function(s) {
	return decodeURIComponent( escape( s ) );
    }
};
UTF8.Test.Speed = UTIL.Test.extend({
    constructor : function(n) {
	this.s1 = UTIL.nchars(12345, n);
    },
    test_0_encode : function() {
	this.s2 = UTF8.encode(this.s1);
	this.success();
    },
    test_1_decode : function() {
	this.s3 = UTF8.decode(this.s2);
	this.success();
    },
    /*
     * Even though it uses native code, its much slower than
     * our self made version.
     *
    test_2_lencode : function() {
	this.s4 = unescape( encodeURIComponent( this.s1 ) );
	this.success();
    },
    test_3_ldecode : function() {
	this.s5 = decodeURIComponent( escape( this.s4 ) );
	this.success();
    },
    test_8_validate : function() {
	if (this.s5 != this.s1) return this.error("ldecode doesnt work.");
	if (this.s4 != this.s2) return this.error("lencode doesnt work");
	this.success();
    },
     */
    /**/
    test_9_validate : function() {
	if (this.s3 != this.s1) return this.error("UTF8 encode/decode dont work");
	return this.success();
    }
});
