
RM    = /usr/bin/rm
JAVA  = /usr/bin/java
KSJAR = /home/ograf/.bin/KickAss/KickAss65CE02.jar
KS    = $(JAVA) -jar $(KSJAR)
C1541 = /usr/bin/c1541
M65   = /home/ograf/.bin/m65

ASMOPTS = 
ifdef BENCHMARK
ASMOPTS += -define BENCHMARK
endif
ifndef NOQ
ASMOPTS += -define JUSTUSEQ
endif

LIBDIR = include
ALLPRG = mand65.prg

all: $(ALLPRG)

disk: MAND65.D81

clean:
# remove all generated files
	$(RM) -rf *.lst *.log *.sym *.prg
# remove disk images
	$(RM) -f MAND65.D81
# cleanup benchmark and tests folder
	$(MAKE) -C benchmark clean
	$(MAKE) -C tests clean

benchmark:
	$(MAKE) -C $@

tests:
	$(MAKE) -C $@

runmand65: mand65.prg
	$(M65) -r mand65.prg

%.prg:	%.s include/*.s
	@echo "Assembling $*.s"
	$(KS) $(ASMOPTS) -libdir $(LIBDIR) $*.s -log $*.log -bytedumpfile $*.lst 2> /dev/null

MAND65.D81: $(ALLPRG)
	$(RM) -f MAND65.D81
	$(C1541) -format "mbexplore65,me" d81 MAND65.D81
	$(C1541) -attach MAND65.D81 -write mand65.prg mand65,prg

.PHONY: all disk benchmark tests clean
