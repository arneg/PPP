#ifndef _ASSERT_H
# define _ASSERT_H

# if (defined(DEBUG) && !defined(NO_ASSERT)) || defined(ASSERT)
#  define assert(x)	enforce(x)
# else
#  define assert(x)	(0)
# endif

# define enforce(x)	(!(x) && error("Assertion (" #x ") failed.\n"))
#endif
