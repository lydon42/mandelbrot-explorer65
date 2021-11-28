#!/usr/bin/python

# https://seaborn.pydata.org/tutorial/color_palettes.html
# -> use seaborn.color_palette directly!

import sys
from PIL import Image
import seaborn as sns

colors = int(sys.argv[1])
reverse = colors<0
colors = abs(colors)
#img = Image.open(sys.argv[2])
pal = sns.color_palette("magma", as_cmap=True)
if reverse:
    pal = pal.reversed()

xpart = pal.N//colors
x = (pal.N - xpart*colors)//2

r, g, b = [], [], []
for i in range(colors):
    col = [int(x*255) for x in pal.colors[x+xpart*i]]
    r.append(col[0]>>4 | ((col[0]<<4)&0xf0))
    g.append(col[1]>>4 | ((col[1]<<4)&0xf0))
    b.append(col[2]>>4 | ((col[2]<<4)&0xf0))

for col in (r, g, b):
    while len(col):
        print("        .byte " + ','.join(['$%02x' % (x,) for x in col[:16]]))
        col = col[16:]
    print()
