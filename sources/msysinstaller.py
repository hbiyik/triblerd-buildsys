'''
Created on 22 Haz 2020

@author: boogie
'''
import os
import sys
import re
import urllib.request
from distutils.version import LooseVersion

tagmap = {"amd64": "x86_64",
         "i386": "i686"}

armap = {"amd64": "64",
         "i386": "32"}

pagecache = "/tmp/pagecache"


def getversion(package):
    versions = [(LooseVersion(x), y) for x, y in re.findall(package + r"\-([0-9\.]+)\-(.+)\-any\.pkg\.tar\.xz(?:\"|\')", page)]
    versions = sorted(versions, reverse=True, key=lambda x: x[0])
    return "%s-%s" % versions[0]


if __name__ == "__main__":
    arch = sys.argv[1]
    package = sys.argv[2]
    repo = "http://repo.msys2.org/mingw/%s" % tagmap[arch]
    if len(sys.argv) > 3:
        version = sys.argv[3]
    else:
        if os.path.exists(pagecache):
            with open(pagecache) as f:
                page = f.read()
        else:
            with open(pagecache, "w") as f:
                page = urllib.request.urlopen(repo).read().decode()
                f.write(page)
        version = getversion(package)
    package = "%s/mingw-w%s-%s-%s-%s-any.pkg.tar.xz" % (repo,
                                                        armap[arch],
                                                        tagmap[arch],
                                                        package,
                                                        version)
    cmd = "cd /work \
    && curl -L --speed-limit 100000 --speed-time 3 --connect-timeout 3 --max-time 30 --retry 5 %s -o target.tar.xz \
    && tar -xf target.tar.xz \
    && rm -f target.tar.xz" % package
    print(cmd)
    sys.exit(os.system(cmd))
