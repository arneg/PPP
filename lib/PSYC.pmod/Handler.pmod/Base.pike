// probably the most efficient/bugfree class in the whole program
//

object uni;

// we tried optional, but that doesn't work - might be a bug, we'll ask the
// pikers soon. in the meantime, we'll use static.
static void create(object o) {
    uni = o;
}

MMP.Uniform string2uniform(string|MMP.Uniform u) {
    if (stringp(u)) return uni->server->get_uniform(u);
    return u;
}
