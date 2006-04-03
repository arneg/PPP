#define unless(x) if(!(x))
#if __EFUN_DEFINED__(strstr)    // pike also provides search() says eMBee
// rexxism: is small an abbreviation of big?
# define abbrev(SMALL, BIG)     (strstr(BIG, SMALL) == 0)
// the same thing at the tail of the string
# define trail(SMALL, BIG)      (strstr(BIG, SMALL, -sizeof(SMALL)) != -1)
#else
# define abbrev(SMALL, BIG)     (SMALL == BIG[0..sizeof(SMALL)-1])
# define trail(SMALL, BIG)      (SMALL == BIG[<sizeof(SMALL)..])
#endif


// 0
// 1 means yes and merge it into psyc
// 2 means yes but do not merge

int(0..2) is_mmpvar(string var) {
    switch (var) {
    case "_target":
    case "_source":
    case "_source_relay":
    case "_source_location":
    case "_source_identification":
    case "_context":
    case "_length":
    case "_counter":
    case "_reply":
    case "_trace":
	return 1;
    case "_amount_fragments":
    case "_fragment":
    case "_encoding":
    case "_list_require_modules":
    case "_list_require_encoding":
    case "_list_require_protocols":
    case "_list_using_protocols":
    case "_list_using_modules":
    case "_list_understand_protocols":
    case "_list_understand_modules":
    case "_list_understand_encoding":
	return 2;
    }
    return 0;
}

