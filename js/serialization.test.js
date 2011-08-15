serialization.SpeedTest = UTIL.Test.extend({
    test_0_encode : function() {
	this.s = this.p.encode(this.m).render();	
	this.success();
    },
    test_1_decode : function() {
	var p = new serialization.AtomParser();
	this.new_m = this.p.decode(p.parse(this.s)[0]);
	this.success();
    }
});
serialization.SpeedTestObject = serialization.SpeedTest.extend({
    constructor : function(n) {
	this.m = {};
	this.n = n;
	for (var i = 0; i < n; i++)
	    this.m[i] = i;
	this.p = new serialization.Object(new serialization.Integer());
    },
    test_4_sanity : function() {
	if (UTIL.keys(this.new_m).sort().join()
	== UTIL.keys(this.m).sort().join())
	    this.success();
	else this.error();
    }
});
serialization.SpeedTestArray = serialization.SpeedTest.extend({
    constructor : function(n) {
	this.m = new Array(n);
	this.n = n;
	for (var i = 0; i < n; i++)
	    this.m[i] = i;
	this.p = new serialization.Array(new serialization.Integer());
    },
    test_4_sanity : function() {
	if (this.new_m.join()
	== this.m.join())
	    this.success();
	else this.error();
    }
});
