#!/usr/bin/python -u
# vim: ai et fileencoding=utf-8 ts=4 sw=4:

'''
    This script will read `list.txt', and write both stdout and `list.err'.
    
    Rules which are comments or regexs will be ignored.
    
    * For `.example.com', if you got anything other than 56, then unless the
      page contains DPI keyword, consider the rule invalid.
    
    * For `||example.com', if you got anything other than 28, then consider
      the rule invalid. (For issue 117, see below.)
    
    * For `|https://*.example.com', if you got anything other than 35, check
      it manually before considering it invalid.
    
    In addition, if you got 6 or 7, check the rule again manually. If in
    doubt, check the rule again manually. Also, please remember: `Garbage
    in, garbage out.'
    
    XXX: As a workaround for issue 117, `|http://example.com/' will be
    tested as `.example.com/'.
'''

from urllib import unquote
import re
import subprocess
import sys

testurl = "http://%s/?"
iplist = ["66.249.89.19", "66.249.89.32", "66.249.89.33", "66.249.89.34", "66.249.89.35", "66.249.89.37", "66.249.89.38", "66.249.89.39", "66.249.89.40", "66.249.89.44", "66.249.89.45", "66.249.89.46", "66.249.89.47", "66.249.89.49", "66.249.89.50", "66.249.89.51", "66.249.89.52", "66.249.89.53", "66.249.89.54", "66.249.89.56", "66.249.89.57", "66.249.89.58", "66.249.89.59", "66.249.89.60", "66.249.89.61", "66.249.89.62", "66.249.89.63", "66.249.89.64", "66.249.89.65", "66.249.89.66", "66.249.89.68", "66.249.89.69", "66.249.89.72", "66.249.89.73", "66.249.89.74", "66.249.89.76", "66.249.89.77", "66.249.89.78", "66.249.89.79", "66.249.89.81", "66.249.89.82", "66.249.89.83", "66.249.89.84", "66.249.89.91", "66.249.89.93", "66.249.89.95", "66.249.89.96", "66.249.89.98", "66.249.89.99", "66.249.89.100", "66.249.89.101", "66.249.89.104", "66.249.89.112", "66.249.89.115", "66.249.89.116", "66.249.89.118", "66.249.89.120", "66.249.89.123", "66.249.89.128", "66.249.89.132", "66.249.89.136", "66.249.89.137", "66.249.89.141", "66.249.89.142", "66.249.89.143", "66.249.89.144", "66.249.89.145", "66.249.89.146", "66.249.89.148", "66.249.89.149", "66.249.89.152", "66.249.89.154", "66.249.89.155", "66.249.89.161", "66.249.89.162", "66.249.89.163", "66.249.89.164", "66.249.89.165", "66.249.89.184", "66.249.89.189", "66.249.89.190", "66.249.89.193", "66.249.89.210", 
          "66.102.13.17", "66.102.13.18", "66.102.13.19", "66.102.13.24", "66.102.13.32", "66.102.13.33", "66.102.13.34", "66.102.13.35", "66.102.13.36", "66.102.13.37", "66.102.13.38", "66.102.13.39", "66.102.13.40", "66.102.13.41", "66.102.13.42", "66.102.13.43", "66.102.13.44", "66.102.13.45", "66.102.13.46", "66.102.13.47", "66.102.13.48", "66.102.13.49", "66.102.13.51", "66.102.13.52", "66.102.13.53", "66.102.13.54", "66.102.13.56", "66.102.13.57", "66.102.13.58", "66.102.13.59", "66.102.13.60", "66.102.13.61", "66.102.13.62", "66.102.13.63", "66.102.13.64", "66.102.13.65", "66.102.13.66", "66.102.13.68", "66.102.13.69", "66.102.13.72", "66.102.13.73", "66.102.13.74", "66.102.13.75", "66.102.13.76", "66.102.13.77", "66.102.13.78", "66.102.13.79", "66.102.13.81", "66.102.13.82", "66.102.13.83", "66.102.13.84", "66.102.13.91", "66.102.13.93", "66.102.13.95", "66.102.13.96", "66.102.13.98", "66.102.13.99", "66.102.13.100", "66.102.13.101", "66.102.13.102", "66.102.13.103", "66.102.13.104", "66.102.13.105", "66.102.13.106", "66.102.13.112", "66.102.13.113", "66.102.13.115", "66.102.13.118", "66.102.13.120", "66.102.13.123", "66.102.13.128", "66.102.13.132", "66.102.13.136", "66.102.13.137", "66.102.13.138", "66.102.13.139", "66.102.13.141", "66.102.13.142", "66.102.13.143", "66.102.13.144", "66.102.13.145", "66.102.13.146", "66.102.13.147", "66.102.13.148", "66.102.13.149", "66.102.13.152", "66.102.13.154", "66.102.13.155", "66.102.13.156", "66.102.13.157", "66.102.13.161", "66.102.13.162", "66.102.13.163", "66.102.13.164", "66.102.13.165", "66.102.13.166", "66.102.13.167", "66.102.13.178", "66.102.13.184", "66.102.13.190", "66.102.13.191", "66.102.13.193", "66.102.13.210"]
offset = 0

INVALID = 0
IP = 1
TLS = 2
URL = 4

expect = {IP: 28, TLS: 35, URL: 56, INVALID: 0}

def getUrl(rule):
    global offset

    if rule.startswith('||'): return ('http://' + rule[2:], IP)
    if rule.startswith('|https'): return (rule[1:], TLS)
    if rule.startswith('|http://'):
        rule = '.' + rule[8:] # XXX: issue 117
    offset += 1
    if offset >= len(iplist): offset = 0
    return (testurl % iplist[offset] + rule, URL)

def main():
    fin = open('list.txt', 'r')
    ferr = open('list.err', 'w')
    line = 0
    if len(sys.argv) > 1:
        startfrom = int(sys.argv[1])
    else:
        startfrom = 0
    for rule in fin:
        line += 1
        rule = rule.strip()
        if line < startfrom: continue
        if not rule: continue
        if rule.startswith('[AutoProxy'): continue
        if rule.startswith('!'): continue
        if rule.startswith('@@'): continue
        if rule.startswith('/') and rule.endswith('/'): continue
        (test, t) = getUrl(rule)
        val1 = subprocess.call(['/usr/bin/curl', '-4', '-I', '-m', '5', test], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        val2 = subprocess.call(['/usr/bin/curl', '-4', '-I', '-m', '5', test], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if (t==IP and val1==28 and val2==28) or (t==TLS and val1==35 or val2==35) or (t==URL and val1==56 or val2==56):
            pass
        elif t==IP and val1==56 or val2==56:
            print line, '\t', test, '=>', '\033[31mexpecting %d, got %d %d\033[0m' % (expect[t], val1, val2)
        else:
            print line, '\t', test, '=>', '\033[1;31mexpecting %d, got %d %d\033[0m' % (expect[t], val1, val2)
            ferr.write(str(line) + ': "' + rule + '", expecting %d, got %d %d' % (expect[t], val1, val2) + '\n')


if __name__ == '__main__':
    main()
