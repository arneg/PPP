#ifndef _ASSERT_H
# define _ASSERT_H

# if (defined(DEBUG) && !defined(NO_ASSERT)) || defined(ASSERT)
#  define assert(x)	enforce(x)
#  define assert(x,r)	enforce(x,r)
# else
#  define assert(x)	(0)
#  define assert(x,r)	(0)
# endif

# define enforce(x)	(!(x) && error("Assertion (" #x ") failed.\n"))
# define enforce(x,r)	(!(x) && error(r + "\n"))
#endif
