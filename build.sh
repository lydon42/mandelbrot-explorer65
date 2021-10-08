#!/bin/sh

acme -r mand65.list mand65.asm

# add man.prg to test disk
c1541 -attach ~/nextCloud/stuff/Hardware/mega65/disks/M65MAN.D81 -delete mand65 -write mand65.prg mand65
