// vim:syntax=lpc
#include <debug.h>


// generic channel/subscription implementation. should be working ok for:
// * places with different channels
// * presence subscription (also having several channels as different groups in the buddylist)
// * sync notifications for storage.
//
// requirements to channels:
// * subscription by the user

// channel -> member -> urks
// this is temporary.. 
mapping(MMP.Uniform:mapping(MMP.Uniform:int)) members = ([ ]);

inherit PSYC.Handler.Base;

constant _ = ([
    "postfilter" : ([
	"_request_context_enter" : 0,
	"_request_context_enter_subscribe" : ({ "_members" }),
    ]),
]);

int postfilter_request_context_enter() {
    return PSYC.Handler.STOP;
}

int postfilter_request_context_enter_subscribe() {
    return PSYC.Handler.STOP;
}
