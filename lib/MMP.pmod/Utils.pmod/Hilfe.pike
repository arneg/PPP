inherit Tools.Hilfe.GenericAsyncHilfe;

void read_callback(mixed id, string s) {
    ::read_callback(id, s);
    inbuffer = "";
}

void write_callback() {
    ::write_callback();
    if (!sizeof(outbuffer)) outfile->set_write_callback(0);
}

void send_output(mixed ... args) {
    ::send_output(@args);
    outfile->set_write_callback(write_callback);
}
