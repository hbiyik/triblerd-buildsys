import subprocess
import re
import os
import sys

installed = re.findall("([\w\-\+\_\.]+)\s+(?:optional)", subprocess.check_output(["dpkg-query", "-Wf", "'${Package;-40}${Priority}\n'"]).decode())

def exceptdep(dep, deps):
    if dep not in deps:
        deps.append(dep)
    try:
        for d in  re.findall(r"(^[\w\-\+\_\.]+| Depends: ([\w\-\+\_\.]+))", subprocess.check_output(["apt-cache", "depends", "--recurse", dep]).decode()):
            if d[-1] not in deps:
                deps.append(d[-1])
    except Exception:
        pass
    return deps


deps = []
for arg in sys.argv[1:]:
    desp = exceptdep(arg, deps)

toremove = [x for x in installed if x not in deps]
with open("cleandeb.sh", "w") as f:
    f.write("apt-get purge -y %s" % " ".join(toremove))
os.system("chmod +x cleandeb.sh")