#version to use

ifndef V
    V = test
endif

all:

crossdomain:
	cp -r CrossDomainPolicy Public_Web_CrossDomainPolicy-$V
	sed -f crossdomain.sed ../lib/MMP.pmod/Utils.pmod/CrossDomainPolicy.pike > Public_Web_CrossDomainPolicy-$V/module.pmod.in/Policy.pike
	sed -f crossdomain.sed ../lib/MMP.pmod/Utils.pmod/FlashFile.pike > Public_Web_CrossDomainPolicy-$V/module.pmod.in/File.pike
	tar cfzvp Public_Web_CrossDomainPolicy-$V.tar.gz --owner root --group root Public_Web_CrossDomainPolicy-$V 

debug:
	cp -r DebugManager Public_Logging_PPP-$V
#sed -f debugmanager.sed ../lib/MMP.pmod/Utils.pmod/DebugManager.pike > Public_Logger_ppp-$V/module.pmod.in/DebugManager.pike
#sed -f debugmanager.sed ../lib/MMP.pmod/Utils.pmod/Debug.pike > Public_Logger_ppp-$V/module.pmod.in/Debug.pike
	cp ../lib/MMP.pmod/Utils.pmod/DebugManager.pike Public_Logging_PPP-$V/module.pmod.in/DebugManager.pike
	cp ../lib/MMP.pmod/Utils.pmod/Debug.pike Public_Logging_PPP-$V/module.pmod.in/Debug.pike
	tar cfzvp Public_Logging_PPP-$V.tar.gz --owner root --group root Public_Logging_PPP-$V 
	- rm -rf Public_Logging_PPP-$V
