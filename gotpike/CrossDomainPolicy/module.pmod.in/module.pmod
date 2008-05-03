//! This is an example of how the CrossDomainPolicy may be used 
//! 
//! 	// allow ports 500-512 from example.org
//! 	Stdio.File file = listener->accept();
//! 	object policy = Public.Web.CrossDomainPolicy.Policy("example.org", 500, 512);
//! 	object cfile = Public.Web.CrossDomainPolicy.File(policy);
//! 	cfile->assign(file);
//! 	// use cfile from now on.	
//! 
 
