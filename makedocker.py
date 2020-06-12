'''
Created on 29 May 2020

@author: boogie
'''
import re
import os
import sys
import logging
import multiprocessing
import subprocess
import shlex
import pprint
import json
import configure
from configparser import SafeConfigParser

    
def runcmd(cmd):
    return  subprocess.Popen(shlex.split(cmd), 
                             stdout=subprocess.PIPE, 
                             stderr=subprocess.PIPE, 
                             stdin=subprocess.PIPE).communicate()


if __name__ == "__main__":
    # get image from arguments
    images = configure.config["images"].keys()
    if len(sys.argv) == 2:
        image = sys.argv[1]
        if image in configure.config["images"]:
            images = [image]
        else:
            logging.error("Can't find image: '%s'" % image)
            logging.info("Available targets: %s" % ",".join(images))
            sys.exit()

    # build images
    logging.info("Building images for targets: %s" % ",".join(images))
    depdata = ""
    for dep, depver in configure.config["deps"].items():
        depdata += "--build-arg %s_SRC=/home/%s " % (dep.upper(),
                                                     configure.findsourcedir(dep))

    # load the old toolchain file
    toolchain = dict(configure.config)
    try:
        with open("dist/toolchain.json") as f:
            extoolchain = json.loads(f)
        for image, imagedata in extoolchain["images"].items():
            toolchain["images"][image]["toolchain"] = imagedata["toolchain"]
    except Exception:
        pass

    failure = False
    for image, cfg in configure.config["images"].items():
        if image in images:
            imagename = "%s/%s-%s" % (configure.DOCKER_USERNAME, configure.DOCKER_IMAGENAME, image)
            targetos = image.split("-")[0]
            cmd = "docker build -t %s \
                  %s \
                  --build-arg BASE=%s \
                  --build-arg QEMU_STATIC=sources/qemu-%s-static \
                  --build-arg THREADS=%s \
                  --build-arg PYVER=%s \
                  --build-arg OPENSSL_PLATFORM=%s \
                  -f %s.dockerfile ." % (imagename,
                                        depdata,
                                        cfg["base"],
                                        cfg["qemu-platform"],
                                        str(multiprocessing.cpu_count()),
                                        configure.config["PYVER"],
                                        cfg["openssl-platform"],
                                        targetos
                                        )
            logging.info("Start building image :%s" % image)
            logging.info(cmd)
            if os.system(cmd):
                failure = True
                logging.error("Failed to build image:  %s" % image)
                break
            if targetos == "linux":
                # get glibc version
                sout, serr = runcmd("docker run -t %s ldd --version" % imagename)
                toolchain["images"][image]["toolchain"]["glibc"] = re.search("([0-9]+\.[0-9]+)", str(sout)).group(1)
            if targetos in ["linux", "android"]:
                # get gcc version
                sout, serr = runcmd("docker run -t %s gcc --version" % imagename)
                toolchain["images"][image]["toolchain"]["gcc"] = re.search("([0-9]+\.[0-9]+\.[0-9]+)", str(sout)).group(1)
            if targetos == "android":
                # get clang version
                sout, serr = runcmd("docker run -t %s clang --version" % imagename)
                toolchain["images"][image]["toolchain"]["clang"] = re.search("([0-9\.\-]+)\s", str(sout)).group(1)
                bldzrconfig = SafeConfigParser()
                bldzrconfig.read('buildozer/buildozer.spec')
                # get ndk version
                toolchain["images"][image]["toolchain"]["ndk"] = bldzrconfig.get("app","android.ndk")
                # get min ndk api
                toolchain["images"][image]["toolchain"]["ndkminapi"] = bldzrconfig.get("app","android.ndk_api")
            with open("dist/toolchain.json", "w") as f:
                f.write(json.dumps(toolchain))
            logging.info("Successfully built image :%s" % image)
    
    if not failure:
        logging.info("build finished with config \r\n %s", pprint.pformat(configure.config))
