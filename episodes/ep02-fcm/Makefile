
RM    = /usr/bin/rm
JAVA  = /usr/bin/java
KSJAR = /home/ograf/.bin/KickAss/KickAss65CE02.jar
KS    = $(JAVA) -jar $(KSJAR)
C1541 = /usr/bin/c1541
M65   = /home/ograf/.bin/m65

LIBDIR = ../../include
ALLPRG = fcmtest.prg

.PHONY: all clean

all: $(ALLPRG)

runfcm: fcmtest.prg
	$(M65) -r fcmtest.prg

clean:
# remove all generated files
	$(RM) -f *.lst *.log *.sym $(ALLPRG)

%.prg:	%.s $(LIBDIR)/*.s
	@echo "Assembling $*.s"
	$(KS) -libdir $(LIBDIR) $*.s -log $*.log -bytedumpfile $*.lst 2> /dev/null
