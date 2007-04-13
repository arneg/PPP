.Queue q = .Queue();

mixed insert(mixed thing) {
    int s = sizeof(q);
    mixed tmp = q->shift();

    q->unshift(thing);
    if (s) q->unshift(tmp);

    next();

    return thing;
}

mixed next() {
    if (sizeof(q)) q->push(q->shift());

    return q->shift_();
}

mixed previous() {
    for (int i = 1; i < sizeof(q); i++) {
	next();
    }

    return current();
}

mixed delete(mixed thing) {
    for (int i = 0; i < sizeof(q); i++) {
	if (q->shift_() == thing) {
	    q->shift();
	    for (int j = i; j > 1; j--) {
		previous();
	    }

	    return previous();
	}

	next();
    }

    return current();
}

mixed current() {
    return q->shift_();
}
