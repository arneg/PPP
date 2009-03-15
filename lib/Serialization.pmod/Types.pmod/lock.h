#define CHECK_LOCKS()	do { if (state->locked()) {\
	    misc->lock = state;\
	    return .LOCKED;\
	} } while(0);
#define LOCK_WALK() do { Serialization.Atom last; foreach (reverse(misc->path);;Serialization.Atom a) {\
			    werror("locking %s by %s\n", a, last||"none");\
			    if (last) a->lock(last);\
			    else a->lock();\
			    last = a;\
			} } while(0);
#define UNLOCK_WALK() do { Serialization.Atom last; foreach (reverse(misc->path);;Serialization.Atom a) {\
			    if (last) a->unlock(last);\
			    else a->unlock();\
			    last = a;\
			} } while(0);
#define CHECK_LOCK()	do { if (state->_locked) {\
	    misc->lock = state;\
	    return .LOCKED;\
	} } while(0);
#define CHECK_CHILD(child) do { if ((child)->locked()) {\
					    misc->lock = child;\
					    return .LOCKED;\
				    } } while(0);
