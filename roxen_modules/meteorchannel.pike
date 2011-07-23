constant module_type = MODULE_PROVIDER|MODULE_LOCATION|MODULE_TAG;
constant module_name = "Webhaven: Meteor.Channel accepter";

mapping(string:function) registered_channels = ([ ]);

inherit Meteor.SessionHandler;

#include <module.h>
inherit "module";

void create() {
    defvar("location", Variable.Location("/meteor/",
		    0, "Virtual Directory to connect meteor connections to",
		    "Browsers have to connect to here when they fire up the meteor connection."));
}

mixed find_file(string file, RequestID r) {
    werror("find_file(%O, %O)\n", file, r);
    {
	mixed id = r;
	NOCACHE();
    }
    mapping id = ([
	    "variables" : r->variables,
	    "answer" : combine(r->send_result, Roxen.http_low_answer),
	    "end" : r->end,
	    "method" : r->method,
	    "request_headers" : r->request_headers,
	    "misc" : ([ 
		    "content_type_type" : r->misc["content_type_type"],
	    ]),
	    "make_response_headers" : make_response_headers,
	    "connection" : r->connection,
	    "data" : r->data,
    ]);
    object session;

    if (id->method == "GET" && !has_index(id->variables, "id")) {
	    session = get_new_session();
	    object multiplexer = Meteor.Multiplexer(session, accept_chan,
						    may_channel);

	    string response = sprintf("_id %s",
				      Serialization.Atom("_string", session->client_id)->render());

	    return ([
		    "data" : Serialization.Atom("_vars", response)->render(),
		    "type" : "text/atom",
		    "error" : 200,
		    "extra_heads" : ([
			    "Cache-Control" : "no-cache",
		    ]),
	    ]);
    }

    // we should check whether or not this is hitting a max connections limit somewhere.
    if ((session = sessions[id->variables["id"]])) {
	    call_out(session->handle_id, 0, id);
	    return Roxen.http_pipe_in_progress();
    }

    werror("unknown session '%O'(%O,%O) in %O\n", id->variables["id"], id->variables, r->variables, sessions);
    return ([
	    "data" : "me dont know you",
	    "type" : "text/plain",
	    "error" : 500,
	    "extra_heads" : ([
		"Connection" : "keep-alive"
	    ])
    ]);
}

string query_provides() {
    return "meteor.channel";
}

int(0..1) may_channel(string name) {
    if (registered_channels[name]) return 1;
    return 0;
}

void accept_chan(object channel, string name) {
    registered_channels[name](channel);
}

int allow_session(string path, RequestID id) {
}

void callback(object session, string path, RequestID id) {
}

void register_channel(string name, function cb) {
    if (registered_channels[name]) error("Channel %O is already registered by %O.\n", name, registered_channels[name]);
    registered_channels[name] = cb;
}

function unregister_channel(string name) {
    return m_delete(registered_channels, name);
}

function get_channel_cb(string name) {
    return registered_channels[name];
}

function combine(function f1, function f2) {
	mixed f(mixed ...args) {
		return f1(f2(@args));
	};

	return f;
}

string make_response_headers(mapping headers) {
	return "HTTP/1.1 200 OK\r\n" + Roxen.make_http_headers(headers);
}

string simpletag_meteorurl(string tagname, mapping args, string content,
		    RequestID id) {
    //werror(">> ID RAW URL >> %O %O %O\n", id->raw_url, id->not_query, id->query);
    //string prefix = id->raw_url[..sizeof(id->raw_url)-sizeof(id->not_query)-sizeof(id->query||"")-2];
    return Standards.JSON.encode(query_location());
}
