#version to use

ifndef V
    V = test
endif

crossdomain:
	cp -r CrossDomainPolicy Public_Web_CrossDomainPolicy-$V
	sed -f crossdomain.sed ../lib/MMP.pmod/Utils.pmod/CrossDomainPolicy.pike > Public_Web_CrossDomainPolicy-$V/module.pmod.in/Policy.pike
	sed -f crossdomain.sed ../lib/MMP.pmod/Utils.pmod/FlashFile.pike > Public_Web_CrossDomainPolicy-$V/module.pmod.in/File.pike
