function get_uniform;
String.Buffer buf = String.Buffer();

void create(function gu) {
    get_uniform = gu;
}

void add(int c) {
    buf->putchar(c);
}

object finish() {
    return get_uniform(buf->get());
}
