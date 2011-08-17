all: utf8.js
%.js: %.js.in stringbuilder.h
	cpp -P $< > $@
