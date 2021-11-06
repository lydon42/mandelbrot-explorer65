
RM = /usr/bin/rm
ACME = /usr/bin/acme
C1541 = /usr/bin/c1541

ALLPRG = mand65lo.prg mand65hi.prg

all: $(ALLPRG) BENCH.D81

clean:
# remove all generated files
	$(RM) -f *.prg *.lst
	$(RM) -f BENCH.D81

%.prg:	%.asm include/*.asm
	@echo "Assembling $*.asm"
	@$(ACME) -r $*.lst $*.asm

BENCH.D81: $(ALLPRG)
	$(C1541) -format "mbexplore65,me" d81 BENCH.D81
	$(C1541) -attach BENCH.D81 -write mand65lo.prg mand65lo,prg -write mand65hi.prg mand65hi,prg

