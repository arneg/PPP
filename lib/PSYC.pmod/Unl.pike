// vim:syntax=lpc
#include <new_assert.h>

//! The simplest PSYC speaking object in whole @i{PSYCSPACE@}. Does
//! Remote Authentication and Reply using uthe 

inherit PSYC.MethodMultiplexer;
inherit Serialization.Signature;
inherit Serialization.BaseTypes;
inherit Serialization.PsycTypes;

object storage;

object server;
MMP.Uniform uni;
mapping(MMP.Uniform:int) counter = ([]);
mapping(MMP.Uniform:object) outstate = ([]);
mapping(MMP.Uniform:object) intstate = ([]);

object method;

object get_outstate(MMP.Packet p) {
    if (!p["_context"]) {
	if (!outstate[p["_target"]]) outstate[p["_target"]] = .State(([]));
	return outstate[p["_target"]];
    }

    error("no mc state for now.\n");
}

object get_instate(MMP.Packet p) {
    if (!p["_context"]) {
	if (!instate[p["_source"]]) instate[p["_source"]] = .State(([]));
	return instate[p["_source"]];
    }

    error("no mc state for now.\n");
}

mixed cast(string type) {
    if (type == "string") return sprintf("Unl(%s)", qName());
}

void check_authentication(MMP.Uniform t, function cb, mixed ... args) {
    call_out(cb, 0, uni == t, @args);
}

void NOP(mixed ... args) { }

//! @param u
//! 	The @[MMP.Uniform] of the new entity.
//! @param s
//! 	The @[PSYC.Server] this entity shall live in.
//! @param stor
//! 	An instance of a @[PSYC.Storage] Storage subclass.
//! @seealso
//! 	@[PSYC.Storage.File], @[PSYC.Storage.Remote], @[PSYC.Storage.Dummy]
//! @note
//!	PSYC entities should not be created anytime anywhere, but by the
//! 	callbacks to the @[PSYC.Server] that will get called if someone
//! 	tries to reach a non-present entity.
void create(mapping params) {
    Serialization.Signature::create(params["type_cache"]);
    PSYC.MethodMultiplexer::create(params); 
    enforce(MMP.is_uniform(uni = params["uniform"]));
    enforce(objectp(server = params["server"]));
    enforce(objectp(storage = params["storage"]));
    debug("local_object", 2, "Uniform created for %s.\n", uni);

    mapping handler_params = params + ([ "parent" : this, "send_message" : send_message,
				         ]);

    method = Method();

    object display = .StageHandler(([ PSYC.Handler.GOON : NOP,
				      PSYC.Handler.STOP : NOP,
				      PSYC.Handler.DISPLAY : NOP ]));
    object postfilter = .StageHandler(([ PSYC.Handler.GOON : display->handle_message,
				         PSYC.Handler.STOP : display->handle_message,
				 	 PSYC.Handler.DISPLAY : display->handle_message ]));
    object filter = .StageHandler(([ PSYC.Handler.STOP : NOP,
				     PSYC.Handler.GOON : postfilter->handle_message,
				     PSYC.Handler.DISPLAY : display->handle_message
				     ]));
    object prefilter = .StageHandler(([ PSYC.Handler.STOP : NOP,
				        PSYC.Handler.GOON : filter->handle_message,
					PSYC.Handler.DISPLAY : display->handle_message
					]));
    // apply state afterwards
    object statestage = .StageHandler(([ PSYC.Handler.STOP : prefilter->handle_message,
				         PSYC.Handler.GOON : prefilter->handle_message ]));

    add_stage("state", statestage);
    add_stage("prefilter", prefilter);
    add_stage("filter", filter);
    add_stage("postfilter", postfilter);
    add_stage("display", display);

    set_start_stage("prefilter");

}

void send_message(PSYC.Message m) {
    server->send_message(m);
}

