RAGEL = ragel
RLCODEGEN = rlcodegen

all: psyc

ps: psyc.ps

ps: psyc.o 
	gcc -g -o psyc psyc.o

pike: psyc.rl
	$(RAGEL) psyc.rl | $(RLCODEGEN) -G2 -o cmod/psyc.cmod && (cd cmod/ && pike -x module)

psyc.c: psyc.rl
	$(RAGEL) psyc.rl | $(RLCODEGEN) -G2 -o psyc.c

psyc.ps: psyc.rl
	$(RAGEL) psyc.rl | $(RLCODEGEN) -Vp | dot -Tps > psyc.ps

%.o: %.c
	gcc -Wall -O3 -g -c -o $@ $<

distclean clean:
	rm -Rf *.o psyc.c psyc psyc.ps
test:
	pike -DDEBUG=50 -I../lib -M../lib test.pike
