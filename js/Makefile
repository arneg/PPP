.PHONY: all

all: utf8.js util.base64.js critbit.js meteor.js util.js
%.js: %.js.in stringbuilder.h util.h
	cpp -P $< > $@
