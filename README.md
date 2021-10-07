
# Mandelbrot Explorer for the MEGA65

This started as an adaption of Matts C64 programs to the MEGA65, but the hires version
was written from scratch to use all the capabilities of the MEGA65.

The goal is to write an explorer style mandelbrot interface for the MEGA65, using all
available math acceleration and 32bit fixed point numbers.

## Platform

The software is tested on xemu MEGA65, using the next branch (advanced VIC-IV) and a
recently patched original rom (920228 or higher).


## Benchmark Stuff

As this started as a Benchmark answer to Matt's 8-bit Battle Royale, there are still the
programs I used for the lowres versions

### Basic Version (m65mand-lowres.bas)

The BASIC65 version is nearly the same as the C64 version. It uses 24bit POKEs to write to
memory (needed for the colour ram located at $1f800).

In addition the RTC of the MEGA65 is used to time the whole mandelbrot loop, so in the end
the time taken is printed to the screen.

It is intended to run in 80x25 text mode, and the timing is printed to the right of the
"graphic".

### Assembler Version (m65mand-lowres.asm)

The assembler version mainly uses the fixedpt routines. I removed the whole conditional part
and made a copy of it, because I needopteded to use acme as assembler.

I decided to use the features available to the 45ce02 cpu, because this is what sets the
different systems apart.

To clear the screen, the dma controller of the MEGA65 is used to clear both screen and colour
ram with a chained dma operation. It also uses the TAB feature to move the base-page to
somewhere else in memory, and then all memory locations in the code use base-page addressing.

To write to the screen and colour ram two 32-bit Base Page Indirect Z-Indexed Mode pointer
are used. I also avoided multiplications in this part, but I don't think that this has a big
impact as the mandelbrot calculations are more prominent in the code.

There is also a new m65mand-hires.bas, which does a hires mandelbrot.
