.PHONY: ppp
ifndef S
    S = fickzoo
endif

ppp:
ifndef D
	pike -DSTILLE_DULDUNG -Ilib -Mlib $(S).pike
else
	pike -DSTILLE_DULDUNG -Ilib -Mlib -DDEBUG=$(D) $(S).pike
endif
