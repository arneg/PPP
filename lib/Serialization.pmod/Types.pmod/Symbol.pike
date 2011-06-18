inherit .ReStringted;

void create() {
    ::create("^[a-z0-9_]+$", Regexp.PCRE.OPTION.MULTILINE|Regexp.PCRE.OPTION.CASELESS);
}
