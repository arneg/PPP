Net.Psyc.Circuit c;



void p_accept(Stdio.Port port) {
    c = Net.Psyc.Circuit(port->accept());
}

int main() {

    string|Psyc.psyc_p ret;
    string t;

    Stdio.Port port = Stdio.Port();
    port->bind(4405, p_accept);
    
    write("c: %O\n", port->query_backend());
    port->set_id(port);
    write("c: %O\n", port->query_id());

    write("c: %O\n", this_thread());

    return -1;
}
