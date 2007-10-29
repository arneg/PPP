//! @returns
//! 	@int
//! 		@value 0
//! 			@expr{candidate@} is not an IP.
//! 		@value 1
//! 			@expr{candidate@} is an IP.
//! 	@endint
//! @fixme
//! 	Support IPv6.
int(0..1) is_ip(string candidate) {

    if (!candidate) return 0;

    array(string) parts = candidate / ".";

    if (sizeof(parts) != 4) return 0;

    foreach (parts;; string part) {
	int pi = (int)part;

	if ((string)pi != part) {
	    return 0;
	}

	if (pi < 0 || pi > 255) return 0;
    }

    return 1;
}
