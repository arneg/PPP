PSYC.Storage storage;
mapping table = ([]);
mapping requested = ([]);
function go_on, stop, error;
string prefix;

void create(string foo, function go_on_, function stop, function error_, PSYC.Storage s) {
    prefix = foo;

    go_on = go_on_;
    stop = stop;
    error = error_;

    storage = s;
}

class AR(object handler, array(string) wvars) {}

void add(string mc, object handler, array(string) wvars) {

    if (!has_index(table, mc)) table[mc] = ({ }); 
    table[mc] += ({ AR(`->(handler, prefix + mc), wvars) });
}

void handle(MMP.Packet p) {

    array(string) l = p->data->mc / "_";
    MMP.Utils.Queue liste = MMP.Utils.Queue(); 

    for (int i = sizeof(l)-1; i >= 0; i--) {
	string temp = l[0..i] * "_";
	if (has_index(table, t)) {
	    foreach(table[t];; object a) {
		liste->push(a);
	    }
	}
    }
    
    // packet2stack[p] = liste;
}

void fetched(string key, string value, MMP.Utils.Queue stack, MMP.Packet p) {

    requested[p][key] = value;

    wvars -= (< key >);

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
	go_on(p);
    }

    multiset wvars = (multiset)stack->shift_()->wvars;

    requested[p] = ([ ]);
    foreach(stack->shift_()->wvars;; string key) {
	storage->get(key, fetched, stack, p, wvars);
    }

}

