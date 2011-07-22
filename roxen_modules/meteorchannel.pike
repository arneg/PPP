constant module_type = MODULE_PROVIDER||MODULE_LOCATION;
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

mixed find_file(string file, RequestID id) {
    NOCACHE();
}

string query_provides() {
    return "meteor.channel";
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
