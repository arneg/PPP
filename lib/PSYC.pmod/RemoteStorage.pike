inherit PSYC.Storage;

MMP.Uniform link_to;
object uni;

void create(MMP.Uniform link_to_, object uni_) {
    link_to = link_to_;
    uni = uni_;
}

// Genereal Retrieve CallBack
void grcb(MMP.Packet p, function callback, string key, array args) {
    PSYC.Packet m = p->data;

    if (key == m["_key"] && search(p->mc, "_notice_retrieve") == 0) {
	call_out(callback, 0, 1, key, m["_value"], @args);
    } else {
	call_out(callback, 0, 0, key, 0, @args);
    }
}

// Generæl Store CallBack
void gscb(MMP.Packet p, function callback, string key, array args) {
    PSYC.Packet m = p->data;

    if (key == m["_key"] && search(p->mc, "_notice_store") == 0) {
	call_out(callback, 0, 1, key, @args);
    } else {
	call_out(callback, 0, 0, key, 0, @args);
    }
}

void get(string key, function callback, mixed ... args) {
    uni->send_tagged(link_to, PSYC.Packet("_request_retrieve", 0, ([
				"_key" : key
			    ])), grcb, callback, key, args);
}

void set(string key, string|array(string) value, function callback, 
	 mixed ... args) {
    uni->send_tagged(link_to, PSYC.Packet("_request_store", 0, ([
				"_key" : key,
				"_value" : value,
			    ])), gscb, callback, key, args);
}
