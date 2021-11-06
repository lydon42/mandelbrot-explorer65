
# Mandelbrot Explorer for the MEGA65

This started as an adaption of Matts C64 programs to the MEGA65, but the hires 
version was written from scratch to use all the capabilities of the MEGA65.

The goal is to write an explorer style mandelbrot interface for the MEGA65, using 
all available math acceleration and 32bit fixed point numbers.

## Platform

The software is tested on xemu MEGA65, using the next branch (advanced VIC-IV) and a
recently patched original rom (920228 or higher).

## Benchmark Stuff

As this started as a Benchmark answer to Matt's 8-bit Battle Royale, there are 
still the programs I used for the lowres and hires version, both in BASIC and Assembler in the benchmark subdir. You can make them by calling `make benchmark`.
