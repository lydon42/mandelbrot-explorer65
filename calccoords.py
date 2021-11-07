#!/usr/bin/env python

import re
import argparse

# http://www.mathcs.emory.edu/~cheung/Courses/255/Syllabus/5-repr/fixed.html

def bin2dec(val):
    neg = 1.0
    if val & 2**31: # negative
        val = (val ^ 0xffffffff) + 1
        neg = -1.0
    return neg * val/2**24

def dec2bin(num):
    isneg = num<0
    num = abs(num)

    integral = int(num)
    fraction = num-integral

    #print(integral, fraction)

    if integral > 127:
        raise ValueError("integral number to large")

    bits = 24
    res = 0
    while bits > 0:
        fraction = fraction * 2
        if int(fraction):
            #print(fraction,1)
            fraction = fraction - 1
            res = res<<1 | 1
        else:
            #print(fraction,0)
            res = res<<1
        bits -= 1

    #print(bin(res), bin(integral))

    res = res | (integral << 24)
    if isneg:
        res = ((res ^ 0xffffffff) + 1) & 0xffffffff

    return res

def formatBinary(val, full=False):
    frac4 = val & 0xff
    frac3 = (val>>8) & 0xff
    frac2 = (val>>16) & 0xff
    frac1 = (val>>24) & 0xff

    #print("0x%08x" % (val,))
    if full:
        return "$%02x, $%02x, $%02x, $%02x // 0x%08x" % (frac4, frac3, frac2, frac1, val)
    return "$%02x, $%02x, $%02x, $%02x" % (frac4, frac3, frac2, frac1)

binre = re.compile(r'((\$|0x)?(?P<long>[0-9a-zA-Z]{8})|(?P<parts>(\$[0-9a-zA-Z]{2},\s*){3}\$[0-9a-zA-Z]{2}))')
numre = re.compile(r'([0-9a-zA-Z]{2})')
def parseBinary(val):
    m = binre.search(val)
    if not m:
        raise ValueError("can't parse hex number")
    if m.group('long'):
        return int(m.group('long'),16)
    return int(''.join(reversed(numre.findall(m.group('parts')))),16)

def parseCoord(val, extend=None):
    x,y = val.split(',')
    x = int(x)
    y = int(y)
    if extend:
        if x >= extend[0] or y >= extend[1]:
            raise ValueError("bigger than screen")
    if x<0 or y<0:
        raise ValueError("negative coords not supported")
    return x,y

def parseRect(val, extend=None):
    a, b = val.split('/')
    return parseCoord(a, extend), parseCoord(b, extend)

valre = re.compile(r'(?P<before>^.*?)//\s*(?P<key>rs|re|is|ie)\s*=\s*(?P<val>[+-]?\d\.\d+)')
def parseParams(val):
    res = {}
    for match in valre.finditer(val):
        val = res[match.group('key')] = float(match.group('val'))
        print(match.groupdict())
        if match.group('before'):
            try:
                val2 = bin2dec(parseBinary(match.group('before')))
            except ValueError:
                pass
            else:
                if dec2bin(val) != dec2bin(val2):
                    print("hex does not match float! %f != %f" % (val2, val))
    if res['rs'] > res['re']:
        raise ValueError("rs > re!")
    if res['is'] > res['ie']:
        raise ValueError("is > ie!")
    return res

def readParams():
    res = {}
    while 1:
        line = input()
        if line.strip() == '':
            break
        m = valre.search(line)
        if m:
            val = res[m.group('key')] = float(m.group('val'))
            try:
                val2 = bin2dec(parseBinary(line))
            except ValueError:
                pass
            else:
                if dec2bin(val) != dec2bin(val2):
                    print("hex does not match float! %f != %f" % (val2, val))
            if not (set(['re','rs','ie','is']) - set(res.keys())):
                break
    return res

def calculateCoords(args):
    dr = (args.params['re'] - args.params['rs']) / args.screen[0]
    di = (args.params['ie'] - args.params['is']) / args.screen[1]
    res = {
        'rs': args.params['rs'] + dr*args.zoom[0][0],
        're': args.params['rs'] + dr*args.zoom[1][0],
        'is': args.params['is'] + di*args.zoom[0][1],
        'ie': args.params['is'] + di*args.zoom[1][1]
    }
    return res

def printResult(res):
    print("        .byte %s // rs=%f" % (formatBinary(dec2bin(res['rs'])), res['rs']))
    print("        .byte %s // re=%f" % (formatBinary(dec2bin(res['re'])), res['re']))
    print("        .byte %s // is=%f" % (formatBinary(dec2bin(res['is'])), res['is']))
    print("        .byte %s // ie=%f" % (formatBinary(dec2bin(res['ie'])), res['ie']))

def main():
    parser = argparse.ArgumentParser("mandelbrot calculator")
    actions = parser.add_mutually_exclusive_group()
    actions.add_argument('--tobinary', '-b', type=float, help="convert float to 32 bit 8.24 binary")
    actions.add_argument('--tofloat', '-f', type=str, help="convert 32 bit 8.24 binary to float")
    actions.add_argument('--zoom', '-z', type=str, help="calculate new coordinates, requires params (x1,y1/x2,y2)")
    parser.add_argument('--screen', default="320,200", help="screensize (default 320,200)")
    parser.add_argument('--params', type=str, help="text containing rs, re, is, ie definitions")

    args = parser.parse_args()

    if args.tobinary:
        print(formatBinary(dec2bin(float(args.tobinary)), True))
    if args.tofloat:
        print(bin2dec(parseBinary(args.tofloat)))
    elif args.zoom:
        args.screen = parseCoord(args.screen)
        args.zoom = parseRect(args.zoom, args.screen)
        if not args.params:
            print("Please paste params (empty line for end):")
            args.params = readParams()
            print()
        else:
            args.params = parseParams(args.params)
        res = calculateCoords(args)
        printResult(res)

if __name__ == '__main__':
    main()
