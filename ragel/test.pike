string p1 = ":_var\t[ \"huhuhi\", \"urks\", {\"key\" :[\"value\"],  \"keu2\":  \"sdfsdfsasd\\n\\\"fd\"}  ]\n:_var2\t\"einfach nur ein komplizierter string, nix wide...\"\n_message_pubic\nurk urs rudkhf";
//string p1 = ":_var\t{\"key\" :[\"value\"],  \"keu2\":  \"sdfsdfsasd\n\\\"fd\"}\n_message_pubic\nurk urs rudkhf";

int main() {
    int ret;

    write("%O\n", Public.Parser.PSYC.parse(p1));
    return 0;
}

