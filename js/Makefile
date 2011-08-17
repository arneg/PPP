all: utf8.js util.base64.js
%.js: %.js.in stringbuilder.h
	cpp -P $< > $@
