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
    for image, cfg in configure.config["images"].items():
        if image in images:
            imagename = "%s/%s-%s" % (configure.DOCKER_USERNAME, configure.DOCKER_IMAGENAME, image)
            targetos = image.split("-")[0]
            cmd = "docker build -t %s \
                  %s \
                  --build-arg BASE=%s \
                  --build-arg QEMU_STATIC=qemu/qemu-%s-static \
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
            logging.info(cmd)
            if os.system(cmd):
                break
            if targetos == "linux":
                sout, serr = runcmd("docker run -t %s gcc --version" % imagename)
                configure.config["images"][image]["toolchain"]["gcc"] = re.search("([0-9]+\.[0-9]+\.[0-9]+)", str(sout)).group(1)
                sout, serr = runcmd("docker run -t %s ldd --version" % imagename)
                configure.config["images"][image]["toolchain"]["glibc"] = re.search("([0-9]+\.[0-9]+)", str(sout)).group(1)

    logging.info("build finished with config \r\n %s", pprint.pformat(configure.config))
    with open("toolchain.json", "w") as f:
        f.write(json.dumps(configure.config))
