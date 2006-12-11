int(0..1) is_ip(string candidate) {
    array(string) parts = candidate / ".";

    if (sizeof(parts) != 4) return 0;

    foreach (parts;; string part) {
	int pi = (int)part;

	if ((string)pi != part) {
	    return 0;
	}

	if (pi < 0 || pi > 256) return 0;
    }

    return 1;
}
