string data, method;
mapping vars;

void create(void|string method, void|string data, void|mapping vars) {
    this_program::method = method;
    this_program::data = data;
    this_program::vars = vars;
}
