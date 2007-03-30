// vim:syntax=lpc
#include <debug.h>
inherit PSYC.Unl;

int linked = 0;
MMP.Utils.Queue queue = MMP.Utils.Queue();
object attachee;
MMP.Uniform link_to;
function subscribe, unsubscribe;

//! Generic PSYC client implementation.
//! Allows for user interfaces and commands (read: functionality) to be added,
//! and does some basic PSYC processing by default.
//!
//! Handlers used by default:
//! @ul
//! 	@item
//! 		@[PSYC.Handler.Subscribe]
//! 	@item
//! 		@[PSYC.Handler.Textdb]
//! @endul

//! @param person
//! 	The uniform the client should link to.
//! @param server
//! 	The @[PSYC.Server] this client runs in.
//! @param unl
//! 	The uniform this client shall have.
//! @param error
//!	Callback to be called when the link fails. Signature:
//! 	@expr{void error(MMP.Packet p, function set_password);@}.
//!
//! 	Signature of set_password is @expr{void set_password(string pw, string|void hash);@},
//! 	with hash beeing the name of the hash method the password was hashed in.
//!
//! 	If you didn't get it yet: Linking will obviously fail if there isn't
//! 	a password given and the @expr{person@} expects one.
//! @param query_password
//! 	Will be called when a password is needed during the linking process.
//! 	Basically the same as @expr{error@}.
void create(MMP.Uniform person, object server, MMP.Uniform unl,
	    function error, function query_password, string|void|int password) {
    link_to = person;

    ::create(unl, server, PSYC.Storage.Remote(this, sendmmp, uni, link_to)); 
    // there will be dragons here
    // (if we directly create a Linker-instance in the add_handlers call,
    // dragons appear.
    // might be a pike bug.
    PSYC.Handler.Base t = PSYC.Handler.Subscribe(this, client_sendmmp, link_to); 
    add_handlers(Linker(this, sendmmp, uni, error, query_password, link_to), 
		 PSYC.Handler.Forward(this, sendmmp, uni), 
		 PSYC.Handler.Textdb(this, sendmmp, uni),
		 t
		 );

    PSYC.Packet request = PSYC.Packet("_request_link");

    if (password) {
	request["_password"] = password;
    }

    sendmmp(link_to, MMP.Packet(request));
}

//! Attach an object to the client.
void attach(object o) {
    attachee = o;
}

//! Detach the object.
void detach() {
    attachee = UNDEFINED;
}

//! Distribute a @[MMP.Packet] to the attached object, calling @expr{msg()@}.
void distribute(MMP.Packet p) {
#if 0
    if (attachee && attachee->msg) {
	attachee->msg(p);
	return;
    } 
#endif

    P3(("PSYC.Client", "Noone using %O. Dropping %O.\n", this, p->data->data))
}

//! Same as standard @[PSYC.Unl()->sendmmp()] but it identifies
//! as the person we linked to using PSYC.Authentication. It
//! is therefore a way to send packets @i{from@} the client @i{as@} the 
//! user.
//! @note
//! 	All packets are queued until the Client is successfully linked to
//! 	the person.
void client_sendmmp(MMP.Uniform target, MMP.Packet p) {

    if (!has_index(p->vars, "_source_identification")) {
	p["_source_identification"] = link_to;
    }

    if (linked) {
	// i dont understand this. why not use
	// the standard sendmmp. probably just
	// wrong.
	//server->sendmmp(target, p);
	sendmmp(target, p);
	return;
    }
    
    queue->push(({ target, p }));
}

void unroll() {
    storage->link();
    while(!queue->isEmpty()) {
	//server->sendmmp(@queue->shift());
	sendmmp(@queue->shift());
    }
}

//! Generate a Person uniform from a local nickname or a full uniform string.
MMP.Uniform user_to_uniform(string l) {
    MMP.Uniform address;
    if (search(l, ":") == -1) {
	l = "psyc://" + link_to->host + "/~" + l;
    }
    address = server->get_uniform(l); 

    return address;
}

//! Generate a Place uniform from a local nickname or a full uniform string.
MMP.Uniform room_to_uniform(string l) {
    MMP.Uniform address;
    if (search(l, ":") == -1) {
	l = "psyc://" + link_to->host + "/@" + l;
    }
    address = server->get_uniform(l); 

    return address;
}

class Linker {
    inherit PSYC.Handler.Base;
    function error, query_password;
    MMP.Uniform link_to;
    
    void create(object c, function sendmmp, MMP.Uniform u, function err, function quer, MMP.Uniform link_to_) {
	error = err;
	query_password = quer;
	link_to = link_to_;
	::create(c, sendmmp, u);
    }

    constant _ = ([
	"postfilter" : ([
	    "_query_password" : 0,
	    "_error_invalid_password" : 0,
	    "_notice_unlink" : 0,
	    "_notice_link" : 0,
	]),
    ]);

    void set_password(string pw, string hash) {
	PSYC.Packet m = PSYC.Packet("_set_password", ([ "_password" : pw ]));
	if (hash) {
	    m["_method_hash"] = hash;
	}
	sendmsg(link_to, m);
    }

    int postfilter_query_password(MMP.Packet p, mapping _v) {
	call_out(query_password, 0, p, set_password);
	return PSYC.Handler.GOON;
    }

    int postfilter_error_invalid_password(MMP.Packet p, mapping _v) {
	call_out(error, 0, p, set_password);
	return PSYC.Handler.STOP;
    }

    int postfilter_notice_unlink(MMP.Packet p, mapping _v) {
	parent->linked = 0;
	return PSYC.Handler.GOON;
    }

    int postfilter_notice_link(MMP.Packet p, mapping _v) {
	parent->linked = 1;
	parent->unroll();
	return PSYC.Handler.GOON;
    }
}


