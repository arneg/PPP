// vim:syntax=lpc

#if Q == 1
# define QUEUE		MMP.Utils.Queue
# define ENQUEUE(x,y)	(x)->push(y)
# define SHIFT(x)	(x)->shift()
# define ISEMPTY(x)	(x)->isEmpty()
# define SIZEOF(x)	sizeof(x)
# define INIT()		QUEUE()
#elif Q == 2
mixed t;
# define QUEUE		array
# define ENQUEUE(x,y)	((x) += ({ (y) }))
# define SHIFT(x)	(t = (x)[0], (x) = (x)[1..], t)
# define ISEMPTY(x)	(sizeof(x) == 0)
# define SIZEOF(x)	sizeof(x)
# define INIT()		allocate(0)
#elif Q == 3
# define QUEUE ADT.Queue
# define ENQUEUE(x,y)	(x)->put(y)
# define SHIFT(x)	(x)->get()
# define ISEMPTY(x)	(x)->is_empty()
# define SIZEOF(x)	sizeof((array)x)
# define INIT()		QUEUE()
#endif

void test1() {
    QUEUE q = INIT();

    for (int i = 1000; i > 0; i--) {
	for (int j = 0; j < i; j++) {
	    if (i & 1) {
		SHIFT(q);
	    } else {
		ENQUEUE(q, j + i);
	    }
	}
    }

    //write("sizeof(q): %d\n", SIZEOF(q));

#if 0
    while (!ISEMPTY(q)) {
	SHIFT(q);
    }
#endif
}

void test2() {
    QUEUE q = INIT();

    for (int i = 0; i < 100000; i++) {
	ENQUEUE(q, i);
    }

    while (!ISEMPTY(q)) {
	SHIFT(q);
    }
}

void test3() {
    QUEUE q = INIT();

    for (int i = 0; i < 10000; i++) {
	ENQUEUE(q, i);
	SHIFT(q);
    }
}

void ttest(function test) {
    int begin = time();
    float bo = time(begin);

    test();

    write("timed: %.032f\n", time(begin)-bo);
}

int main() {
    array tests = ({ test1, test2, test3 });

    ttest(tests[*]);

    return 0;
}
