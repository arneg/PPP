import Protocols.HTTP;

object http_server, parser;
mapping(string:object) sessions = ([]);

string decode(string f) {

    array(int) list = enumerate(255);
    array(string) chars = String.int2char(list[*]);
    array(string) hex = sprintf("%%%2X", list[*]);

    return replace(f, hex, chars);
}

void pr(mixed ... args) {
    werror("pr: %O\n", args);
}

void callback(Server.Request r) {
    werror("type: %O\n", r->request_type);
    werror("query: %O\n", r->full_query);

    if (r->request_type == "GET") {
	if (has_suffix(r->full_query, ".html") || has_suffix(r->full_query, ".js")) {
	    string file = Stdio.read_file(r->full_query[1..]);
	    r->response_and_finish(([
		    "data" : file,
	    ]));

	    werror("delivered %O (%d)\n", r->full_query[1..], sizeof(file));
	    return;
	}
    } 

    if (has_prefix(r->full_query, "/bayeux")) {
	string s;

	if (r->request_type == "GET" && !sizeof(r->query)) {
	    while (has_index(sessions, s = sprintf("%@x", (random_string(10)/"")[*][0]))) {}

	    werror("gave away client-id: %O\n", s);

	    sessions[s] = PSYC.Meteor.Session(s, pr, pr);

	    r->response_and_finish(([ 
		"data" : s,
		"type" : "text/atom",
	    ]));
	    return;
	}

	if (has_index(sessions, r->query)) {
	    sessions[r->query]->handle(r);
	}

    } else {
	werror("raw: %O\n", r->raw);
    }
}

int main(int argc, array(string) argv) {
    string ip;
    
    if (argc > 1) {
	ip = argv[1];
    }

    werror("ip: %O\n", ip);

    http_server = Server.Port(callback, 1080, ip);
    parser = Serialization.AtomParser();

    return -1;
}
