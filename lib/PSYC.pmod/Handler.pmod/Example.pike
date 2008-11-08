
int init_handler() {
    
    register_incoming("filter", "_message_test1", ([ "v":vsig, "d":dsig, "fetch":ssig->index("test1data") ]));
    register_incoming(0,"_message_test2", ([ "v":vsig, "d":dsig ]));
    register_outgoing("_notice_test2", ([ "v":vsig, "d":dsig ]));
    
    return 1;
}


