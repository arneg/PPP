#include <debug.h>

constant prefilter = 	([ 
    "_message_public" : ({ "_logsize" }),
]);
constant filter 	= 	([ 
    "_message_public" : ({ "_null", "_password" }),
]);
constant postfilter = 	([ 
    "_message_public" : ({ "_foo", "_bar", "_flu" }),
]);


int prefilter_message_public(MMP.Packet p, mapping _v) {
    return 1;
}

int filter_message_public(MMP.Packet p, mapping _v) {

    P0(("DemoHandler", "filter_message_public(%O, %O)\n", p, _v))

    if (search(p->data->data, _v["_password"]) != -1) return 0;
    return 1;
}

int postfilter_message_public(MMP.Packet p, mapping _v) {
    P0(("DemoHandler", "%O got through.\n", p));    
    return 1;
}
