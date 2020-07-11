#!/usr/bin/env python3
'''
Created on 29 Mar 2020

@author: boogie
'''
import os
import re
import sys
import shutil
import logging
import hashlib
import argparse
from configure import DOCKER_IMAGENAME, DOCKER_USERNAME, android_platforms, targets


logging.basicConfig(level=logging.INFO)

parser = argparse.ArgumentParser()
parser.add_argument('--target')
parser.add_argument('--srcdir')
parser.add_argument('--test', action='store_true')
parser.add_argument('--debugrun', action='store_true')
args = parser.parse_args()
if not args.srcdir or not os.path.exists(args.srcdir):
    logging.error("Please provide tribler root directory as --srcdir argument")
    sys.exit()
else:
    root_dir = os.path.realpath(args.srcdir)
if (args.test or args.debugrun) and args.target is None:
    logging.error("--test or --debugrun flag must be used for a specific target, no targets given")
    sys.exit()
elif args.test and args.debugrun:
    logging.error("you can not have --test and --debugrun flags together")
    sys.exit()
elif args.target is None:
    logging.info("No specific target provided, building for %s" % ", ".join(targets))
    buildtargets = targets
elif args.target not in targets:
    logging.error("No such target %s, valid targets are %s" % (args.target, ", ".join(targets)))
    sys.exit()
else:
    logging.info("Building for specific target %s" % args.target)
    buildtargets = {args.target: targets[args.target]}
    
    
docker_dir = os.path.abspath(os.path.dirname(os.path.abspath(__file__)))


def runindocker(cmd, container, dirmap=None, hostnetwork=False, privileged=True, paths=None, wine=False):
    if paths:
        if wine:
            paths = "set PYTHONPATH=%s" % ";".join(paths)
            cmd = 'wine cmd /c \\"%s & set & %s\\"' % (paths, cmd)
        else:
            paths = "export PYTHONPATH=$PYTHONPATH:%s" % ":".join(paths)
            cmd = "%s && export && %s" % (paths, cmd)
    dockercmd = 'docker run -ti %s %s %s\
                 %s/triblerd-%s \
                 /bin/bash -c "%s"' % ("--network host" if hostnetwork else "",
                                       "--privileged" if privileged else  "",
                                       " ".join(["-v %s:%s" % (x, y) for x, y in dirmap]) if dirmap else "",
                                       DOCKER_USERNAME,
                                       container,
                                       cmd)
    logging.info("Running in docker(%s): %s" % (container, cmd))
    print(dockercmd)
    return os.system(dockercmd)

   
def build(target, container):
    ostype, _ = container.split("-")
    # map tribler source dir
    drvmap =  [(root_dir, "/work/tribler")]
    if ostype == "windows":
        paths = ["Z:\\work\\tribler\\src\\anydex",
                 "Z:\\work\\tribler\\src\\tribler-common",
                 "Z:\\work\\tribler\\src\\tribler-core",
                 "Z:\\work\\tribler\\src\\pyipv8"]
        if args.debugrun:
            pycmd = "Z:\\work\\python\\python Z:\\work\\tribler\\src\\tribler-core\\run_tribler_headless.py -p 8085"
        elif args.test:
            drvmap.append((os.path.join(docker_dir, "utils", "testrunner.py"), "/work/testrunner.py"))
            pycmd = "Z:\\work\\python\\python Z:\\work\\testrunner.py --srcdir=Z:\\work\\tribler"
        else:
            drvmap.append((os.path.join(docker_dir, "dist"), "/work/dist"))
            drvmap.append((os.path.join(docker_dir, "triblerd.spec"), "/work/triblerd.spec"))
            pycmd = "Z:\\work\\python\\python -m PyInstaller Z:\\work\\triblerd.spec -y --onefile \
                    --distpath Z:\\work\\dist\\triblerd-%s" % container
        if not runindocker(pycmd,
                           container,
                           drvmap,
                           True,
                           False,
                           paths,
                           True) and not args.debugrun and not args.test:
            return "dist/triblerd-%s/triblerd.exe" % container

    elif ostype in "linux":
        paths = ["/work/tribler/src/anydex",
                 "/work/tribler/src/tribler-common",
                 "/work/tribler/src/tribler-core",
                 "/work/tribler/src/pyipv8"]
        if args.debugrun:
            pycmd = "python3 /work/tribler/src/tribler-core/run_tribler_headless.py -p 8085"
        elif args.test:
            # map test runner to tribler source root
            drvmap.append((os.path.join(docker_dir, "utils", "testrunner.py"), "/work/testrunner.py"))
            pycmd = "python3 /work/testrunner.py --srcdir=/work/tribler"
        else:
            # map release directory to pyinstaller release directory
            drvmap.append((os.path.join(docker_dir, "dist"), "/work/dist"))
            # map pyinstaller spec file to source root directoy,
            # this is different that tribler spec file since it is aiming only the headless tribler
            drvmap.append((os.path.join(docker_dir, "triblerd.spec"), "/work/triblerd.spec"))
            pycmd = "python3 -m PyInstaller /work/triblerd.spec -y --onefile \
                    --distpath /work/dist/triblerd-%s" % container
        if not runindocker(pycmd,
                           container,
                           drvmap,
                           True,
                           False,
                           paths) and not args.test and not args.debugrun:
            
            # return the path for generated file
            return "dist/triblerd-%s/triblerd" % container

    elif ostype == "android":
        # map release directory to buildozer release directory
        drvmap.append((os.path.join(docker_dir, "dist"), "/work/buildozer/dist"))
        if args.debugrun or args.test:
            # run in privileged mode and use host socket
            hasadb = True
            # map usb devices to container
            drvmap.append(("/dev/bus/usb", "/dev/bus/usb")),
            drvmap.append((os.path.join(os.path.expanduser("~"), ".android", "adbkey"), "/home/kivy/.android/adbkey"))
            drvmap.append((os.path.join(os.path.expanduser("~"), ".android", "adbkey.pub"), "/home/kivy/.android/adbkey.pub"))
            if args.test:
                #replace main.py with test runner
                drvmap.append((os.path.join(docker_dir, "utils", "testrunner.py"), "/work/buildozer/main.py"))
            buildozercmd = "buildozer android debug deploy run logcat"
        else:
            hasadb = False
            buildozercmd = "buildozer android release"
        if not runindocker('cd /work/buildozer && \
                            python3 alterspec.py app:android.arch=%s app:requirements=triblercore && \
                            %s' % (android_platforms[target],
                                   buildozercmd),
                            container,
                            drvmap,
                            hasadb,
                            hasadb,
                            ):
            # find the generated apk and move it to a standart folder, and return the final path
            for fname in os.listdir(os.path.join(docker_dir, "dist")):
                if re.search("triblerd.+%s.+\.apk$" % android_platforms[target], fname):
                    fpath = os.path.join(docker_dir, "dist", fname)
                    target = "triblerd-%s" % target
                    os.makedirs(os.path.join(docker_dir, "dist", target), exist_ok=True)
                    fpath_new = os.path.join(docker_dir, "dist", target, "triblerd.apk")
                    shutil.move(fpath, fpath_new)
                    return fpath_new

for target in buildtargets:
    logging.info("Building tribler for '%s' from source: %s", target, root_dir)
    shutil.rmtree(os.path.join(root_dir, "build", "triblerd"), True)
    artifact = build(target, buildtargets[target])
    if not artifact:
        break
    # calculate the sha256 checsum of the generated file
    sha256_hash = hashlib.sha256()
    with open(artifact,"rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    with open("%s.sha256" % artifact, "w") as f:
        f.write(sha256_hash.hexdigest())
