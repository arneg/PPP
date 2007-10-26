// vim:syntax=lpc
// probably the most efficient/bugfree class in the whole program

#include <debug.h>

//! This is the base class for all handlers to enable things handlers need, and to grant a type to all those classes who want to
//! participate in the handling of PSYC.
//! @fixme
//!	Move initing stuff to a special class that can be included by only those modules who do init().

inherit PSYC.HandlingTools;

int _init;
array _init_cb_queue;

//! @returns
//! 	Returns true if the module is inited, false otherwise
int is_inited() {
    return _init;
}

//! Sets the status of the handler
//! @param i
//!	Handler will claim to be inited if @expr{i@} is @expr{true@}, @expr{false@} otherwise.
//!
//! @note
//!	Calls @[call_init_callbacks()]
void set_inited(int i) {
    _init = i;
    if (i) {
	debug("Handler.Base", 2, "INITED %O. Calling %O.\n", this, _init_cb_queue);
	call_init_callbacks();
    }
}

//! @decl void init_cb_add(function cb, mixed ... args)
//! Add a callback to the queue to be executed when the handler has been inited.
//! @param cb
//!	Callback to be called.
//! @param args
//!	Optional arguments to be passed to the callback.
//! @note
//!	Do not call this function unless you are a @[StageHandler] or really know what you are doing!
void init_cb_add(mixed ... cb) {
    if (!_init_cb_queue) _init_cb_queue = ({ });

    _init_cb_queue += ({ cb });
}

//! Call this to call all message-callbacks that have queued up while the module was not inited.
//! @note
//!	Gets called by @[set_inited]@expr{(true)@} automagically, do not call yourself unless you really need to.
void call_init_callbacks() {
    if (_init_cb_queue) {
	foreach (_init_cb_queue;; array tmp) {
	    call_out(tmp[0], 0, @tmp[1..]);
	}

	_init_cb_queue = 0;
    }
}
