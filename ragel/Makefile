RAGEL = ragel
RLCODEGEN = rlcodegen
PIKESOURCE = /home/el/tmp/Pike-v7.6.86/src

all: psyc

ps: psyc.ps

pike: psyc.rl
	$(RAGEL) psyc.rl | $(RLCODEGEN) -G2 -o psyc.c && gcc -DPIKE -Wall -O2 -g -I$(PIKESOURCE) psyc.c -o pike

ps: psyc.o 
	gcc -g -o psyc psyc.o

psyc.c: psyc.rl
	$(RAGEL) psyc.rl | $(RLCODEGEN) -G2 -o psyc.c

psyc.ps: psyc.rl
	$(RAGEL) psyc.rl | $(RLCODEGEN) -Vp | dot -Tps > psyc.ps

%.o: %.c
	gcc -Wall -O3 -g -c -o $@ $<

distclean clean:
	rm -Rf *.o psyc.c psyc psyc.ps
