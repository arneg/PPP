// vim:syntax=lpc
#include <debug.h>
inherit PSYC.Unl;

int linked = 0;
MMP.Utils.Queue queue = MMP.Utils.Queue();
object attachee;
MMP.Uniform link_to;
function subscribe, unsubscribe;

void create(MMP.Uniform uni_, object server, MMP.Uniform unl,
	    function error, function query_password, string|void password) {
    PSYC.Packet request = PSYC.Packet("_request_link");
    link_to = uni_;

    ::create(unl, server, PSYC.RemoteStorage(link_to, this)); 
    // there will be dragons here
    // (if we directly create a Linker-instance in the add_handlers call,
    // dragons appear.
    // might be a pike bug.
    PSYC.Handler.Base t = PSYC.Handler.Subscribe(this, client_sendmsg); 
    add_handlers(Linker(this, error, query_password, link_to), 
		 PSYC.Handler.Forward(this), 
		 PSYC.Handler.Textdb(this),
		 t
		 );
    subscribe = t->subscribe;
    unsubscribe = t->unsubscribe;

    if (password) {
	request["_password"] = password;
    }

    sendmsg(link_to, request);
}

void attach(object o) {
    attachee = o;
}

void detach() {
    attachee = UNDEFINED;
}

void distribute(MMP.Packet p) {
    if (attachee) {
	attachee->msg(p);
	return;
    } 

    PT(("PSYC.Client", "Noone using %O. Dropping %O.\n", this, p->data->data))
}

void client_sendmsg(MMP.Uniform target, PSYC.Packet m) {
    MMP.Packet p = MMP.Packet(m, ([
	"_target" : target,
	"_source_identification" : link_to,
	"_source" : uni,
    ]));

    client_sendmmp(p, target);
}

void client_sendmmp(MMP.Packet p, MMP.Uniform|void target) {

    if (!target) {
	target = p["_target"];
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

MMP.Uniform user_to_uniform(string l) {
    MMP.Uniform address;
    if (search(l, ":") == -1) {
	l = "psyc://" + link_to->host + "/~" + l;
    }
    address = server->get_uniform(l); 

    return address;
}

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
    
    void create(object c, function err, function quer, MMP.Uniform link_to_) {
	error = err;
	query_password = quer;
	link_to = link_to_;
	::create(c);
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
	uni->sendmsg(link_to, m);
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
	uni->linked = 0;
	return PSYC.Handler.GOON;
    }

    int postfilter_notice_link(MMP.Packet p, mapping _v) {
	uni->linked = 1;
	uni->unroll();
	return PSYC.Handler.GOON;
    }
}


