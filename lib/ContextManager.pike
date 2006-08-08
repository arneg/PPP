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
mapping(MMP.Uniform:ContextSlave) contexts = ([]);

int msg(MMP.Packet p) {
   
    PSYC.Packet m = p->data;

    switch (m->mc) {
    case "_request_enter":
	{
	    // the variable naming is somehow beta
	    MMP.Uniform context = m["_identification"];
	    // is there a case where a context master inherits the context manager
	    // class? if yes, we need to think about making the difference clear 
	    // inside the protocol
	    if (has_index(contexts, context)) {
		contexts[context]->insert(p["_source"]); 	
	    }
	}
    case "_request_leave":
	{
	    MMP.Uniform context = m["_identification"];

	    if (has_index(contexts, context)) {
		contexts[context]->remove(p["_source"]); 	
	    }
	}
    }
    
    return 0;
}
