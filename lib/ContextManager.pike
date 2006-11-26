#include <debug.h>
// we need some information for each context about the conference control in 
// that context. for some we are allowed to add anyone as a listener to that 
// context or even as a sender. examples:
// - friendcast: the context manager may add listeners (his friends) but 
//   noone is allowed to send casts but the context master
// - managed room: the context manager has to ask the master before adding 
//   listeners to the context. the master may ask to context manager to add
//   listeners to his context. (someone asks the master directly and he decides
//   to add him to a context slave somewhere else)
// - unmanaged room: similar to the friendcast. context manager may add senders 
//   too and cast messages.
inherit PSYC.Unl;

mapping(MMP.Uniform:ContextSlave) contexts = ([]);

int msg(MMP.Packet p) {
    ::msg(p);

    P2(("ContextManager", "%O->msg(%O)\n", this, p))

    if (has_index(p->vars, "_context")) {
	MMP.Uniform c = p->vars["_context"];
	if (has_index(contexts, c)) {
	    contexts[c]->msg(p); 
	} else {
	    P0(("ContextManager", "%O->Got a message (%O) for %O although I do not have a Slave distributing on that context.", this, p, c))
	}
	return 1;
    }
   
    PSYC.Packet m = p->data;

    switch (m->mc) {
    case "_request_enter":
	{
	    // the variable naming is somehow beta
	    if (!has_index(p->vars, "_target_relay")) {
		sendmsg(p["_source"], m->reply("_failure_request_enter")); 

		return 1;
	    }
	    MMP.Uniform context = p["_target_relay"];
	    // is there a case where a context master inherits the context manager
	    // class? if yes, we need to think about making the difference clear 
	    // inside the protocol
	    sendmmp(context, MMP.Packet(tag(PSYC.Packet("_request_enter")),
				     ([ "_source_relay" : p["_source"] ])));
	    return 1;
	}
    case "_notice_enter":
	{
	    if (!has_index(m->vars, "_tag_reply")) {
		// evil, wrong tag.. or none. 
		return 1;
	    }

	    // we have to check if the user actually asked us
	    if (!has_index(p->vars, "_target_relay")) {
		// complain here
		P2(("ContextManager", "Got a _notice_enter from %O without a _target_relay.\n", p["_source"]))

		return 1;
	    }
	    MMP.Uniform source = p["_source"];

	    if (!has_index(contexts, source)) {
		ContextSlave o = ContextSlave(server);
		server->register_context(source, o);
		o->insert(p["_target_relay"]);
		contexts[source] = o;
	    } else {
		contexts[source]->insert(p["_target_relay"]);
	    }

	    sendmmp(p["_target_relay"], MMP.Packet(PSYC.Packet("_echo_enter"), 
						   ([
					"_source_relay" : source,
						    ])));
	    return 1;
	}
    case "_request_leave":
	{ 
	    if (!has_index(p->vars, "_target_relay")) {
		sendmsg(p["_source"], m->reply("_failure_request_leave"));

		return 1;
	    }
	    if (!has_index(contexts, p["_target_relay"])) {
		sendmsg(p["_source"], m->reply("_failure_request_leave", ([ "_nick_place" : p["_target_relay"] ])));

		return 1;
	    }

	    PSYC.Packet req = PSYC.Packet("_request_leave");
	    void cb(MMP.Packet reply, MMP.Packet orig) {
		P0(("ContextMaster", "The reply %O to\n %O.\n", reply, orig))
		P0(("ContextMaster", "contexts: %O\n", contexts))
		if (reply->data->mc == "_echo_leave") {
		    if (has_index(contexts, orig["_target_relay"])) {
			MMP.Uniform room = orig["_target_relay"];
			//TODO we may check here if all variables fit to each other
			// e.g. _target_relay == _source
			//      _source == _source_relay
			
			contexts[room]->remove(orig["_source"]); 	
			sendmmp(orig["_source"], MMP.Packet(orig->data->reply("_echo_leave"), ([ "_source_relay" : room ])));
			return;
		    }
		}
		P0(("ContextManager", "Something went wrong with the _echo_leave (%O)\n", reply))
	    };

	    tag(req, cb, p);
	    sendmmp(p["_target_relay"], MMP.Packet(req, ([ "_source_relay" : p["_source"] ])));

	    return 1;
	}
    }
    
    return 0;
}
