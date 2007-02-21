#ifndef _ASSERT_H
# define _ASSERT_H

# if (defined(DEBUG) && !defined(NO_ASSERT)) || defined(ASSERT)
#  define assert(x)	enforce(x)
// r for reason
#  define assertr(x,r)	enforcer(x,r)
# else
#  define assert(x)	(0)
// r for reason
#  define assertr(x,r)	(0)
# endif

# define enforce(x)	(!(x) && error("Assertion (" #x ") failed.\n"))
// r for reason
# define enforcer(x,r)	(!(x) && error(r + "\n"))
#endif
