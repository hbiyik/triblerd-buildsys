'''
Created on 7 Haz 2020

@author: boogie
'''

import sys
try:
    from configparser import SafeConfigParser
except ImportError:
    from ConfigParser import SafeConfigParser

args = sys.argv[1:]
config = SafeConfigParser()
config.read('buildozer.spec')

for arg in sys.argv[1:]:
    section, data = arg.split(":")
    print(section, data)
    key, value = data.split("=")
    config.set(section, key.strip(), value.strip())
with open('buildozer.spec', "w") as fd:
    config.write(fd)