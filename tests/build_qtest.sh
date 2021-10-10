#!/bin/sh

acme -r qtest.list qtest.asm

# add man.prg to test disk
c1541 -attach ~/nextCloud/stuff/Hardware/mega65/disks/M65MAN.D81 -delete qtest -write qtest.prg qtest
