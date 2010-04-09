inherit Tools.Hilfe.GenericAsyncHilfe;

void read_callback(mixed id, string s) {
    ::read_callback(id, s);
    inbuffer = "";
}
