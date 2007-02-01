# Copyright 2007 Tobias Josefowitz
# Distributed under the terms of the GNU General Public License v2

inherit toolchain-funcs

IUSE=""
DESCRIPTION="compiler/parser compiler"
HOMEPAGE="http://www.cs.queensu.ca/~thurston/ragel/"
SRC_URI="${HOMEPAGE}${P}.tar.gz"

LICENSE="GPL-1"
SLOT="0"
KEYWORDS="x86"

DEPEND="virtual/libc"

src_install() {
	make PREFIX="${D}/usr" install || die
}
