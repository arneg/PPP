array(mixed) xargs;
object obj;

void create(object o, mixed ... args) {
    xargs = args;
    obj = o;
}

mixed `->(string index) {
    function f;
    write("%O->%O\n", obj, index);
    if (functionp(f = predef::`->(obj, index))) {
	mixed fun(mixed ... args) {
	   return f(@args, @xargs); 
	};

	return fun;
    }

    return f;
}
