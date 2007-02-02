#ifndef _ASSERT_H
# define _ASSERT_H
# if (defined(DEBUG) && !defined(NO_ASSERT)) || defined(ASSERT)
#  define assert(x)	if (!(x)) error("Assertion (" #x ") failed.\n")
# else
#  define assert(x)
# endif

# define enforce(x)	if(!(x)) error("Enforcing (" #x ") with this " \
				       "throw.\n")
#endif
