// vim:syntax=lpc


constant _ = ([
    "handler1" : ([
	"spec" : ([  
	    "to" : Person, // Person is a class
	    "type" : "message",
	    "child" : ([]), // same kind of spec here for the child
	    "attribute1" : "string",
	]),
    ]),
    "handler2" : ([
    ])
]);


void handler1(XMLNode node) {

}

void handler2(XMLNode node) {

}
