mixed pointee;
int offset;

void create(mixed pointee, int|void offset) {
    this_program::pointee = pointee;
    this_program::offset = offset;
}

object `+(mixed first, mixed ... rest) {
    write("%O, %O\n", first, rest);
    return this_program(pointee, predef::`+(offset, first, @rest));
}

object ``+(mixed first, mixed ... rest) {
    write("`%O, %O\n", first, rest);
    return this_program(pointee, predef::`+(offset, first, @rest));
}

object `+=(object first, mixed ... rest) {
    write("=%O, %O\n", first, rest);
    offset = predef::`+(offset, first, @rest);

    return this;
}

object `-(mixed|void other) {
    if (zero_type(other)) {
	error("no such thing as a negation of this.\n");
    }

    return this_program(pointee, offset-other);
}

mixed `[](mixed ... args) {
    if (sizeof(args) == 1) {
	return pointee[args[0]+offset];
    } else {
	return pointee[args[0]+offset..args[1]+offset];
    }
}

mixed `[]=(mixed arg1, mixed arg2) {
    return pointee[arg1+offset] = arg2;
}

mixed `()() {
    return pointee[offset];
}
