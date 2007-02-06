string p1 = ":_var\t[ \"huhuhi\", \"urks\", {\"key\" :[\"value\"],  \"keu2\":  \"sdfsdfsasd\\n\\\"fd\"}  ]\n:_var2\t\"einfach nur ein komplizierter string, nix wide...\"\n_message_pubic\nurk urs rudkhf";
//string p1 = ":_var\t{\"key\" :[\"value\"],  \"keu2\":  \"sdfsdfsasd\n\\\"fd\"}\n_message_pubic\nurk urs rudkhf";

int main() {
    int ret;

    object factory() {                                                                                                                
        return JSON.UniformBuilder(this->server->get_uniform);                                                                        
    };                                                                                                                                
                                                                                                                                      
    mixed parse_JSON(string d) {                                                                                                      
        return JSON.parse(d, 0, 0, ([ '\'' : factory ]));                                                                             
    };                         

    PSYC.Packet a = PSYC.Packet();

    if (ret = Public.Parser.PSYC.parse(p1, a)) {
	write("parsing of \n%s\n failed in state %d to &d. \n", p1, ret, ret << 16);
    } else {
	write("c: %O, %O\n", a, a->vars);
    }

    PSYC.parse(p1, parse_JSON, a);
    write("c: %O, %O\n", a, a->vars);

    write("c parser used %f\n", gauge{
	Public.Parser.PSYC.parse(p1, a);
    });
    write("pike parser used %f\n", gauge{
	PSYC.parse(p1, parse_JSON, a);
    });

    return 0;
}

