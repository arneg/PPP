// This is a roxen module. 
// (c) 2007      Webhaven.
//
// prot_psyc.pike
// Roxen PSYC Protocol Object
//
//  This code is (c) 2007 Webhaven.
//  it can be used, modified and redistributed freely
//  under the terms of the GNU General Public License, version 2.
//
//  This code comes on a AS-IS basis, with NO WARRANTY OF ANY KIND, either
//  implicit or explicit. Use at your own risk.
//  You can modify this code as you wish, but in this case please
//  - state that you changed the code in the modified version
//  - do not remove our name from it
//  - if possible, send us a copy of the modified version or a patch, so that
//    we can include it in the 'official' release.
//  If you find this code useful, please e-mail us. It would definitely
//  boost our ego :)
//
//  For risks and side-effects please read the code or ask your local
//  unix or roxen-guru.


inherit Protocol;
constant supports_ipless = 0;
constant name = "psyc";
constant prot_name = "psyc";
constant default_port = 4044;
constant requesthandlerfile = "protocols/psyc.pike";
