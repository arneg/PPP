
int init_handler() {
    
    register_incoming(([ "stage" : "filter", "method":Method("_message_test1"), "vars":vsig, "data":dsig, "fetch":ssig->index("test1data")->query() ]));
    
    register_outgoing(([ "method":Method("_message"), vsig:vsig, dsig:Int() ]));
    return 1;
}

object vsig, dsig;

int t() {
    MMP.Packet p = MMP.Packet();

    // do something with p

    Message m = get_message("_message", p);

    m->assign();// do some state changes

    send(Message());
}


