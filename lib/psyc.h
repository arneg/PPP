#define PMIXED	string|array(string|int)|int

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

