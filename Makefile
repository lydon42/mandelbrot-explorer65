
RM = /usr/bin/rm
JAVA = /usr/bin/java
ACME = /usr/bin/acme
KICKASS65JAR = /home/ograf/.bin/KickAss/KickAss65CE02.jar
KS   = $(JAVA) -jar $(KICKASS65JAR)
C1541 = /usr/bin/c1541

ALLPRG = test.prg

all: $(ALLPRG)

disk: MAND65.D81

clean:
# remove all generated files
	$(RM) -f *.sym *.dbg *.prg *.lst
# remove disk images
	$(RM) -f MAND65.D81
	$(MAKE) -C benchmark clean

benchmark:
	$(MAKE) -C $@

%.prg:	%.ks include/*.ks
	@echo "Assembling $*.ks"
	@$(KS) $*.ks -log $*.log -bytedumpfile $*.lst 2> /dev/null

MAND65.D81: $(ALLPRG)
	$(RM) -f MAND65.D81
	$(C1541) -format "mbexplore65,me" d81 MAND65.D81
	$(C1541) -attach MAND65.D81 -write test.prg test,prg

.PHONY: all disk benchmark clean
