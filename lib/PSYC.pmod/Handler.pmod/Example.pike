
int init_handler() {
    
    register_incoming(([ "stage" : "filter", "method":Method("_message_test1"), "vars":vsig, "data":dsig, "fetch":ssig->index("test1data")->query() ]));
    
    return 1;
}


