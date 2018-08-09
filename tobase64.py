#! /usr/bin/python

import base64
import sys

sl = len(sys.argv)
if sl == 1:
    tag = 0
else:
    tag = 1

print(tag)

if tag == 0:
    print("encode")
    fo = open("./gfwlist-raw.txt")
    so = fo.read()
    fo.close()
    
    sb64 = base64.b64encode(so)
    
    ft = open("./gfwlist-tiny.txt", "w")
    i = 0;
    for s in sb64 :
        ft.write(s)
        i = i + 1
        if i % 64 == 0 :
            ft.write("\n")
    
    ft.close()
else:
    print("decode")
    fo = open("./gfwlist.txt")
    s = base64.b64decode(fo.read())
    fo.close()
    ft = open("./gfwlist-temp.txt", "w")
    ft.write(s)
    ft.close()

print("done")