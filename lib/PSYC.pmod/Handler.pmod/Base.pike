// vim:syntax=lpc
// probably the most efficient/bugfree class in the whole program
//
#include <debug.h>

object uni;
function sendmmp;

// we tried optional, but that doesn't work - might be a bug, we'll ask the
// pikers soon. in the meantime, we'll use static.
static void create(object o, function _sendmmp) {
    uni = o;

    sendmmp = _sendmmp;
}

string send_tagged_v(MMP.Uniform target, PSYC.Packet m, multiset(string)|mapping wvars,
		     function callback, mixed ... args) {
    uni->tagv(m, callback, wvars, @args); 
    call_out(sendmsg, 0, target, m);
    return m["_tag"];
}

string send_tagged(MMP.Uniform target, PSYC.Packet m, 
		   function callback, mixed ... args) {
    return send_tagged_v(target, m, 0, callback, @args);
}

void sendmsg(MMP.Uniform target, PSYC.Packet m) {
    P3(("PSYC.Unl", "sendmsg(%O, %O)\n", target, m))
    MMP.Packet p = MMP.Packet(m, 
			  ([ "_source" : uni,
			     "_target" : target ]));
    sendmmp(target, p);    
}
