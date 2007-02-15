RAGEL = ragel
RLCODEGEN = rlgen-cd -G2

all: psyc

ps: psyc.ps

ps: psyc.o 
	gcc -g -o psyc psyc.o

pike: psyc.rl
	$(RAGEL) -e psyc.rl | $(RLCODEGEN) -o cmod/psyc.cmod && (cd cmod/ && pike -x module)

psyc.c: psyc.rl
	$(RAGEL) psyc.rl | $(RLCODEGEN) -o psyc.c

psyc.ps: psyc.rl
	$(RAGEL) psyc.rl | $(RLCODEGEN) -Vp | dot -Tps > psyc.ps

json_string.c: json_string.rl
	$(RAGEL) json_string.rl | $(RLCODEGEN) -o json.cmod/json_string.c

json_mapping.c: json_mapping.rl
	$(RAGEL) json_mapping.rl | $(RLCODEGEN) -o json.cmod/json_mapping.c

json_array.c: json_array.rl
	$(RAGEL) json_array.rl | $(RLCODEGEN) -o json.cmod/json_array.c

json_number.c: json_number.rl
	$(RAGEL) json_number.rl | $(RLCODEGEN) -o json.cmod/json_number.c

json.cmod: json_string.c json_mapping.c json_array.c json_number.c
	$(RAGEL) -e json.rl | $(RLCODEGEN) -o json.cmod/json.cmod && (cd json.cmod/ && pike -x module)

json.ps: json.rl json_string.rl json_mapping.rl json_array.rl json_number.rl
	$(RAGEL) json.rl | $(RLCODEGEN) -Vp | dot -Tps > json.ps
	$(RAGEL) json_string.rl | $(RLCODEGEN) -Vp | dot -Tps > json_string.ps
	$(RAGEL) json_mapping.rl | $(RLCODEGEN) -Vp | dot -Tps > json_mapping.ps
	$(RAGEL) json_array.rl | $(RLCODEGEN) -Vp | dot -Tps > json_array.ps
	$(RAGEL) json_number.rl | $(RLCODEGEN) -Vp | dot -Tps > json_number.ps

%.o: %.c
	gcc -Wall -O3 -g -c -o $@ $<

distclean clean:
	rm -Rf *.o psyc.c psyc psyc.ps
test:
	pike -I../lib -M../lib test_json.pike
