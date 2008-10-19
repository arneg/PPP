/*
    Copyright (C) 2008 Tobias S. Josefowitz

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.


		    GNU GENERAL PUBLIC LICENSE
		       Version 2, June 1991

 Copyright (C) 1989, 1991 Free Software Foundation, Inc.,
 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

			    Preamble

  The licenses for most software are designed to take away your
freedom to share and change it.  By contrast, the GNU General Public
License is intended to guarantee your freedom to share and change free
software--to make sure the software is free for all its users.  This
General Public License applies to most of the Free Software
Foundation's software and to any other program whose authors commit to
using it.  (Some other Free Software Foundation software is covered by
the GNU Lesser General Public License instead.)  You can apply it to
your programs, too.

  When we speak of free software, we are referring to freedom, not
price.  Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
this service if you wish), that you receive source code or can get it
if you want it, that you can change the software or use pieces of it
in new free programs; and that you know you can do these things.

  To protect your rights, we need to make restrictions that forbid
anyone to deny you these rights or to ask you to surrender the rights.
These restrictions translate to certain responsibilities for you if you
distribute copies of the software, or if you modify it.

  For example, if you distribute copies of such a program, whether
gratis or for a fee, you must give the recipients all the rights that
you have.  You must make sure that they, too, receive or can get the
source code.  And you must show them these terms so they know their
rights.

  We protect your rights with two steps: (1) copyright the software, and
(2) offer you this license which gives you legal permission to copy,
distribute and/or modify the software.

  Also, for each author's protection and ours, we want to make certain
that everyone understands that there is no warranty for this free
software.  If the software is modified by someone else and passed on, we
want its recipients to know that what they have is not the original, so
that any problems introduced by others will not reflect on the original
authors' reputations.

  Finally, any free program is threatened constantly by software
patents.  We wish to avoid the danger that redistributors of a free
program will individually obtain patent licenses, in effect making the
program proprietary.  To prevent this, we have made it clear that any
patent must be licensed for everyone's free use or not licensed at all.

  The precise terms and conditions for copying, distribution and
modification follow.

		    GNU GENERAL PUBLIC LICENSE
   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

  0. This License applies to any program or other work which contains
a notice placed by the copyright holder saying it may be distributed
under the terms of this General Public License.  The "Program", below,
refers to any such program or work, and a "work based on the Program"
means either the Program or any derivative work under copyright law:
that is to say, a work containing the Program or a portion of it,
either verbatim or with modifications and/or translated into another
language.  (Hereinafter, translation is included without limitation in
the term "modification".)  Each licensee is addressed as "you".

Activities other than copying, distribution and modification are not
covered by this License; they are outside its scope.  The act of
running the Program is not restricted, and the output from the Program
is covered only if its contents constitute a work based on the
Program (independent of having been made by running the Program).
Whether that is true depends on what the Program does.

  1. You may copy and distribute verbatim copies of the Program's
source code as you receive it, in any medium, provided that you
conspicuously and appropriately publish on each copy an appropriate
copyright notice and disclaimer of warranty; keep intact all the
notices that refer to this License and to the absence of any warranty;
and give any other recipients of the Program a copy of this License
along with the Program.
*/

// =======================================================================
// =======================================================================
// __                                          .         
// | \   _   __     ._ _   __  ._  _|_  _  _|_    _  ._  
// |  ) / \ /   | | | | | /__) | \  |  / |  |  | / \ | \ 
// |_/  \_/ \__ |_|_| | | \___ | (_ |_ \_|_ |_ |_\_/ | (_
//
// =======================================================================
// everybody complains when there is none, so now better read it!!
// =======================================================================
//
// this mapping class uses typeof(x) + "\1" + x; as hashing method.
// this means that strings, booleans and numbers can safely be used as indices.
// additionally, any other types where this gives sufficient distinction can
// be used totally or at least partially, e.g. arrays: arrays of numbers and
// booleans and strings which do NOT have "," in them can be used safely.
//
// an example of indices that do not work well (together):
// var mapping = new Mapping();
// mapping.set([2,3], "hey");
// mapping.get(["2,3"]); // returns "hey" which might not be desired.
//
// =======================================================================
// =======================================================================

function Mapping() {
    this.m = new Object();
    this.n = new Object();
    this.length = 0;

    this.sfy = function(key) { // sfy ==> stringify
	return typeof(key) + "\0" + key;
    };

    this.set = function(key, val) {
	var key2 = this.sfy(key);

	if (!this.m.hasOwnProperty(key2)) {
	    this.length++;
	}

	this.m[key2] = val;
	this.n[key2] = key;
    };

    this.get = function(key) {
	return this.m[this.sfy(key)];
    };

    // IE doesn't like this being called "delete", so, beware!
    this.remove = function(key) {
	var key2 = this.sfy(key);

	if (this.hasIndex(key)) {
	    this.length--;
	}

	delete this.m[key2];
	delete this.n[key2];
    };

    this.indices = function() {
	var ret = new Array();
	
	for (var i in this.n) {
	    ret.push(this.n[i]);
	}

	return ret;
    };

    this.foreach = function(cb) {
	for (var i in this.n) {
	    cb(this.n[i]);
	}
    };

    this.toString = function() {
	return "Mapping(:" + this.length + ")";
    };

    this.hasIndex = function(key) {
	return this.m.hasOwnProperty(this.sfy(key));
    };

    this.reset = function() {
	this.m = new Object();
	this.length = 0;
    };
}

// =======================================================================
// if your head hurts now, you should've just read the documentation.
// =======================================================================
