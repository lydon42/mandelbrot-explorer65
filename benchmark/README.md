# Mandelbrot Benchmarks

These where created as an answer to MAtt Haffernans Battle Royale video blogs.

## BASIC Lo-Res (m65mand-lowres.bas)

The BASIC65 version is nearly the same as the C64 version. It uses 24bit POKEs to 
write to memory (needed for the colour ram located at $1f800).

In addition the RTC of the MEGA65 is used to time the whole mandelbrot loop, so in 
the end the time taken is printed to the screen.

It is intended to run in 80x25 text mode, and the timing is printed to the right of the "graphic".

## BASIC Hi-Res (m65mand-hires.bas)

Uses BASIC65 Graphics commands ands draws a 640x400 Mandelbrot with 48 iterations 
in 256 colour mode.

A bit of math optimizations compared to the Lo-Res version.

## Assembler Lo-Res (mand65lo.asm)

The assembler version mainly uses the fixedpt routines. I removed the whole 
conditional part and made a copy of it, because I opted to use acme as assembler.

I decided to use the features available to the 45ce02 cpu, because this is what 
gets the different systems apart.

To clear the screen, the dma controller of the MEGA65 is used to clear both screen 
and colour ram with a chained dma operation. It also uses the TAB feature to move 
the base-page to somewhere else in memory, and then all memory locations in the 
code use base-page addressing.

To write to the screen and colour ram two 32-bit Base Page Indirect Z-Indexed Mode 
pointer are used. I also avoided multiplications in this part, but I don't think 
that this has a big impact as the mandelbrot calculations are more prominent in the 
code.

## Assembler Hi-Res (mand65hi.asm)

Uses 32 bit fixed point numbers with a 8.24 layout. This was a big learning 
experience of how to program graphics in FCM mode.

If you press a key while the fractal is drawn, it will exit directly after 
finishing and display the timing using the BASIC TI variable. If you don't do that, 
the timing displayed will be wrong, because it stops counting when the assembler is 
exited and BASIC takes over again.
