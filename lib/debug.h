#ifdef DEBUG
# define P0(ding)	MMP.debug ding;
# if DEBUG > 0
#  define P1(ding)	MMP.debug ding;
# else
#  define P1(ding)
# endif
# if DEBUG > 1
#  define P2(ding)	MMP.debug ding;
# else
#  define P2(ding)
# endif
# if DEBUG > 2
#  define P3(ding)	MMP.debug ding;
# else
#  define P3(ding)
# endif
# if DEBUG > 3
#  define P4(ding)	MMP.debug ding;
# else
#  define P4(ding)
# endif
#else
# define P0(ding)
# define P1(ding)
# define P2(ding)
# define P3(ding)
# define P4(ding)
#endif
