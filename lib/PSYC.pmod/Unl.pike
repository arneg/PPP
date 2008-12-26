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

//! Entry point for processing PSYC messages through this handler framework.
//! @param p
//! 	An @[MMP.Packet] containing parseable PSYC as a string or @[PSYC.Packet].
//!
//! 	This will do everything from throwing to nothing if you provide something else.
void msg(MMP.Packet p) {
    debug("packet_flow", 3, "%O: msg(%O)\n", this, p);
    
    if (p["content_type"] == "psyc") {
	int f;
	switch (sprintf("%t", p->data)) {
	case "string":
	    object parser = Serialization.AtomParser();
	    object a = parser->parse(p->data);

	    if (!a) do_throw("uuuahahah");
	    p->data = a;
	    f = 1;
	case "object":
	    if (f || Program.inherits(object_program(p->data), Serialization.Atom)) {
		object parser = Serialization.AtomParser();
		array(Serialization.Atom) t = parser->parse_all();
		PSYC.Packet packet = PSYC.Packet();

		int i;

		for (i = 0;i < sizeof(t); i++) {
		    Serialization.atom = t[i];
		    if (atom->is_subtype_of("_mapping") && !atom->action) {
			if (i > 0) {
			    packet->state_changes = t[0..i-1];
			}
			packet->vars = t[i];

			i++;
			break;
		    } 
		}
		if (t[i]->is_subtype_of(method)) {
		    packet->mc = method->decode(t[i]);
		    if (sizeof(t) == ++i) {
			packet->data = t[i];
		    } else if (sizeof(t) > i){
			error("more than one data. looks broken.\n");
		    }
		} else {
		    error("broken psyc packet.\n");
		}

		p->data = packet;
		stages[start_stage]->handle_message(p, p->data->mc);
		break;
	    } else if (Program.inherits(object_program(p->data), Serialization.Atom)) {
		stages[start_stage]->handle_message(p, p->data->mc);
		break;
	    } else {
		do_throw("p->data is an object, but neither of class PSYC.Packet nor Serialization.Atom\n");
	    }
	    break;
	    default:
	    debug("packet_flow", 1, "Got Packet without data. maybe state changes?\n");
	    break;
	}
	
    }
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

