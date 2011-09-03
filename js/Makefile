all: utf8.js util.base64.js critbit.js
%.js: %.js.in stringbuilder.h
	cpp -P $< > $@
