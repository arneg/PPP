// This is a roxen protokol module. 
// (c) 2007 Arne Goedeke, Martin Bähr, Tobias S. Josefowitz, Webhaven
//
// prot_psyc.pike
// Roxen PSYC Protocol Object

inherit Protocol;
constant supports_ipless = 0;
constant name = "psyc";
constant prot_name = "psyc";
constant default_port = 4044;
constant requesthandlerfile = "protocols/psyc.pike";
mapping servers = ([]);
