// vim:syntax=lpc
// probably the most efficient/bugfree class in the whole program
//

object uni;
function sendmsg, sendmmp;

// we tried optional, but that doesn't work - might be a bug, we'll ask the
// pikers soon. in the meantime, we'll use static.
static void create(object o, function|void fun1, function|void fun2) {
    uni = o;

    sendmsg = fun1 || o->sendmsg;
    sendmmp = fun2 || o->sendmmp;
}
