// vim:syntax=lpc
#include <new_assert.h>

//! The simplest PSYC speaking object in whole @i{PSYCSPACE@}. Does
//! Remote Authentication and Reply using uthe 

inherit PSYC.Handling;
inherit Serialization.Signature : signature;
inherit Serialization.BaseTypes;
inherit Serialization.PsycTypes;

object storage;

object server;
object state = .State();
MMP.Uniform uni;
mapping(MMP.Uniform:int) counter = ([]);

object method;

mixed cast(string type) {
    if (type == "string") return sprintf("Unl(%s)", qName());
}

MMP.Uniform qName() {
    return uni;
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
    ::create(params); 
    signature::create(Serialization.TypeCache());
    enforce(MMP.is_uniform(uni = params["uniform"]));
    enforce(objectp(server = params["server"]));
    enforce(objectp(storage = params["storage"]));
    debug("local_object", 2, "Uniform created for %s.\n", uni);

    mapping handler_params = params + ([ "parent" : this, "sendmmp" : sendmmp ]);

    PSYC.MethodMultiplexer(params + ([ "handling" : this ]));
    PSYC.NotifyHandling(params + ([ "handling" : this ]));

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
    object statestage = .StageHandler(([ PSYC.Handler.STOP : prefilter->handle_message,
				         PSYC.Handler.GOON : prefilter->handle_message ]));

    add_stage("state", statestage);
    add_stage("prefilter", prefilter);
    add_stage("filter", filter);
    add_stage("postfilter", postfilter);
    add_stage("display", display);

    set_start_stage("prefilter");

    add_handlers(
		 PSYC.Handler.Auth(handler_params),
		 PSYC.Handler.Reply(handler_params)
		 );
}



//! Send an @[MMP.Packet]. MMP routing variables of the packet will be set automatically if possible.
//! @param target
//!	The target to be used if there is not a target specified in @expr{packet@}.
//! 	Otherwise only the hostname of this will be used as the physical target, all other needed informations 
//!	will be fetched from @expr{packet@}.
//! @param packet
//! 	The @[MMP.Packet] to send.
void sendmmp(MMP.Uniform target, MMP.Packet packet) {
    debug("packet_flow", 1, "%O->sendmmp(%O, %O)\n", this, target, packet);
    
    if (!has_index(packet->vars, "_context")) {
	if (!has_index(packet->vars, "_target")) {
	    packet["_target"] = target;
	}

	if (!has_index(packet->vars, "_source")) {
	    packet["_source"] = uni;
	}

	if (!has_index(packet->vars, "_counter")) {
	    packet["_counter"] = counter[packet["_source"]]++;
	}
    }

    server->deliver(target, packet);
}

