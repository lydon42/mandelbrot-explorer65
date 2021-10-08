#!/usr/bin/python

import sys
from PIL import Image, ImageDraw

MAX_ITER = 48

def hexify(v):
    v2 = int(abs(v) * (2**24))
    if v < 0:
        v2 = (v2^0xffffffff)+1
    return '%08X' % (v2,)

def mandelbrot(cr, ci):
    zr = cr
    zi = ci
    n = MAX_ITER - 1
    max_r, max_i = 0.0, 0.0
    while n > 0:
        #print(hexify(zr), hexify(zi))
        zr2 = zr*zr
        zi2 = zi*zi
        if zr2 + zi2 > 4:
            break
        zrt = zr2 - zi2 + cr
        zi = 2*zr*zi + ci
        zr = zrt
        max_r = max(max_r, zr)
        max_i = max(max_i, zi)
        n -= 1
    return n, max_r, max_i

#mandelbrot(-0.859382152557373, -0.3937540054321289)
#sys.exit(1)

# Image size (pixels)
WIDTH = 320
HEIGHT = 200

# Plot window
RE_START = -2.5
RE_END = 1
IM_START = -1.3125
IM_END = 1.3125

palette = []

im = Image.new('RGB', (WIDTH, HEIGHT), (0, 0, 0))
draw = ImageDraw.Draw(im)

mmr, mmi = 0.0, 0.0
for x in range(0, WIDTH):
    for y in range(0, HEIGHT):
        # Convert pixel coordinate to complex number
        c = complex(RE_START + (x / WIDTH) * (RE_END - RE_START),
                    IM_START + (y / HEIGHT) * (IM_END - IM_START))
        # Compute the number of iterations
        m, mr, mi = mandelbrot(c.real, c.imag)
        mmr = max(mmr, mr)
        mmi = max(mmi, mi)
        # The color depends on the number of iterations
        color = 255 - int(m * 255 / MAX_ITER)
        # Plot the point
        draw.point([x, y], (color, color, color))

print(mmr, mmi)
im.save('output.png', 'PNG')
