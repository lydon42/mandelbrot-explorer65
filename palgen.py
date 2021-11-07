#!/usr/bin/python

import sys
from PIL import Image

colors = int(sys.argv[1])
reverse = colors<0
colors = abs(colors)
img = Image.open(sys.argv[2])

xpart = img.size[0]//colors
x = (img.size[0] - xpart*colors)//2
y = img.size[1]//2

if reverse:
    xpart = -xpart
    x = img.size[0]-x

r, g, b = [], [], []
for i in range(colors):
    col = img.getpixel((x+xpart*i,y))
    r.append(col[0]>>4 | ((col[0]<<4)&0xf0))
    g.append(col[1]>>4 | ((col[1]<<4)&0xf0))
    b.append(col[2]>>4 | ((col[2]<<4)&0xf0))

for col in (r, g, b):
    while len(col):
        print("        .byte " + ','.join(['$%02x' % (x,) for x in col[:16]]))
        col = col[16:]
    print()
