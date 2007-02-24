// vim:syntax=lpc
//
inherit .Volatile;


void create() {
    mapping(string:mixed) data = ([
	"_friends" : ([ ]),
	"_subscriptions" : ([ ]),
	"_password" : "test",
	"_groups" : ([]),
	"places" : ([]),
    ]);

    ::create(data);
}

void save() { }
