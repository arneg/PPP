string type;
string data;

mixed pdata;
int parsed;

void create(string type, string data) {
    this->type = type;
    this->data = data;
}

array(string) subtypes() {
    return .subtypes(type);	
}

int(0..1) is_subtype_of(this_program a) {
    return .is_subtype_of(type, a->type);
}

int(0..1) is_supertype_of(this_program a) {
    return .is_supertype_of(type, a->type);
}
