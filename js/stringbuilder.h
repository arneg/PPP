#define BUF_INIT()	var _buf = [], _C = new Array(256), _i = 0
#define BUF_PUTCHAR(c)	do { _C[_i++] = (c); } while(0)
#define BUF_CHECK()	do { if (_i == _C.length) { _buf.push(String.fromCharCode.apply(String, _C)); _i = 0; } } while(0)
#define BUF_ADD(s)	do { if (_i > 0) { _buf.push(String.fromCharCode.apply(String, _C.slice(0, _i))); _i=0; } _buf.push(s); } while(0)
#define BUF_FINISH()	do { if (_i > 0) { _buf.push(String.fromCharCode.apply(String, _C.slice(0, _i))); _i=0; } } while(0)
#define BUF_GET()	_buf.join("")
