.PHONY: ppp

ppp:
ifndef D
	pike -Ilib -Mlib fickzoo.pike
else
	pike -Ilib -Mlib -DDEBUG=$(D) fickzoo.pike
endif
