serialization.SpeedTest = UTIL.Test.extend({
    constructor : function(n) {
	this.m = {};
	for (var i = 0; i < n; i++) {
	    this.m[i] = i;
	}
	this.p = new serialization.Object(new serialization.Integer());
    },
    test_0_encode : function() {
	this.s = this.p.encode(this.m).render();	
	this.success();
    },
    test_1_decode : function() {
	var p = new serialization.AtomParser();
	var m = this.p.decode(p.parse(this.s)[0]);
	this.success();
    }
});
