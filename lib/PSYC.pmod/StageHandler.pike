#include <debug.h>

PSYC.Storage storage;
mapping table = ([]);
mapping requested = ([]);
function go_on, stop, error;
string prefix;

void create(string foo, function go_on_, function stop_, function error_, PSYC.Storage s) {
    prefix = foo;

    go_on = go_on_;
    stop = stop_;
    error = error_;

    storage = s;
}

class AR(function handler, array(string) wvars) {}

void add(string mc, object handler, array(string) wvars) {

    if (!has_index(table, mc)) table[mc] = ({ }); 
    table[mc] += ({ AR(`->(handler, prefix + mc), wvars) });

    P0(("StageHandler", "table: %O\n", table))
}

void handle(MMP.Packet p) {

    P2(("StageHandler", "%s:handle(%O)\n", prefix, p))

    array(string) l = p->data->mc / "_";
    MMP.Utils.Queue liste = MMP.Utils.Queue(); 

    for (int i = sizeof(l)-1; i >= 0; i--) {
	string temp = l[0..i] * "_";
	if (has_index(table, temp)) {
	    foreach(table[temp];; object a) {
		liste->push(a);
	    }
	}
    }

    P0(("StageHandler", "stack for %O is %O\n", p, (array)liste))
    progress(liste, p);
}


void fetched(string key, string value, MMP.Utils.Queue stack, MMP.Packet p,
	     multiset(string) wvars) {
    P2(("StageHandler", "fetched(%O, %O, %O, %O, %O)\n", key, value, stack,
	p, wvars))

    requested[p][key] = value;

    if (wvars[key]) while(--wvars[key]);

    if (!sizeof(wvars)) {
	mapping tmp = m_delete(requested, p);

	if (stack->shift()->handler(p, tmp)) {
	    progress(stack, p);
	} else {
	    stop(p);
	}
    }
}

void progress(MMP.Utils.Queue stack, MMP.Packet p) {

    if (stack->isEmpty()) {
	call_out(go_on, 0, p);

	return;
    }

    multiset wvars = (multiset)stack->shift_()->wvars;

    requested[p] = ([ ]);
    foreach(stack->shift_()->wvars;; string key) {
	storage->get(key, fetched, stack, p, wvars);
    }

}

