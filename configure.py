'''
Created on 6 Haz 2020

@author: boogie
'''
import logging
import os
import shutil
import urllib.request
import json

logging.basicConfig(level=logging.INFO)

DOCKER_USERNAME = "boogiepy"
DOCKER_IMAGENAME = "triblerd"

with open("packages.json") as f:
    packages  = json.loads(f.read())

PYVER = ".".join(packages["python"][0].split(".")[:2])

qemurepo = "https://github.com/multiarch/qemu-user-static/releases/download/v5.0.0-2/"

config = {"images":
            {"linux-i386":
                {"base": "debian/eol:lenny-slim@sha256:a2230f615ba41081b6727b32234275064e4f53de77dc94765fcaa24489d6f930",
                 "openssl-platform": "linux-x86",
                 "qemu-platform": "i386",
                 "toolchain": {},
                 "targets": ["linux-i386"]
                 },
            "linux-amd64":
                {"base": "debian/eol:lenny-slim@sha256:4211c70bd47b74942957b208e9f54cb52eaa15b0b48c3d76f3f9b502929d1d01",
                 "openssl-platform": "linux-x86_64",
                 "qemu-platform": "x86_64",
                 "toolchain": {},
                 "targets": ["linux-amd64"]
                 },
            "linux-armel":
                {"base": "debian/eol:lenny-slim@sha256:859461d1c5e8e39244a803fef8cad2b840cd9198542d7edc0bada781f5794b1a",
                 "openssl-platform": "linux-generic32",
                 "qemu-platform": "arm",
                 "toolchain": {},
                 "targets": ["linux-armel"]
                 },
            "linux-armhf":
                {"base": "debian/eol:wheezy-slim@sha256:54a2fa7015ca274803d8e64f622a375057efa89d3595bb9148d62aa657b3b3c8",
                 "openssl-platform": "linux-armv4",
                 "qemu-platform": "arm",
                 "toolchain": {},
                 "targets": ["linux-armhf"]
                 },
            "linux-aarch64":
                {"base": "debian/eol:jessie-slim@sha256:600ca584836c903364017aea8f4ca4af335f04c949a7dd78801477cf3cb6cdc5",
                 "openssl-platform": "linux-aarch64",
                 "qemu-platform": "aarch64",
                 "toolchain": {},
                 "targets": ["linux-aarch64"]
                 },
            "android-buildozer":
                {"base": "python:3.7-slim-buster@sha256:fecbb1a9695d25c974906263c64ffba6548ce14a169ed36be58331659383c25e",
                 "openssl-platform": "",
                 "qemu-platform": "x86_64",
                 "toolchain": {},
                 "targets": ["android-i386", "android-amd64", "android-armhf", "android-aarch64"]
                 },
            },
        "deps":{pname:pval[0] for pname, pval in packages.items()},
        "PYVER": PYVER
        }

targets = {}

for imagename, image in config["images"].items():
    for targetname in image["targets"]:
        targets[targetname] = imagename 

android_platforms = {"android-i386": "x86",
                     "android-amd64": "x86_64",
                     "android-armhf": "armeabi-v7a",
                     "android-aarch64": "arm64-v8a"
                     }


def findsourcedir(package):
    for d in os.listdir("sources"):
        sdir = os.path.join("sources", d)
        if os.path.isdir(sdir) and d.lower().startswith(package.lower()):
            return sdir


# sync qemu
for image in config["images"]:
    if config["images"][image].get("qemu-platform"):
        url = "%sx86_64_qemu-%s-static.tar.gz" % (qemurepo,
                                                   config["images"][image]["qemu-platform"])
        binname = "qemu-%s-static" % config["images"][image]["qemu-platform"]
        if not os.path.exists("sources/%s" % binname):
            logging.info("Downloading Qemu : %s", url)
            urllib.request.urlretrieve(url, "sources/%s.archive" % binname)
            shutil.unpack_archive("sources/%s.archive" % binname, "sources", "gztar")

# sync packages
for package, (version, url) in packages.items():
    if not os.path.exists("sources/%s.download" % package):
        logging.info("Downloading package: %s, from:%s", package, url)
        urllib.request.urlretrieve(url, "sources/%s.archive" % package)
        with open("sources/%s.download" % package, "w") as f:
            f.write(url)
    srcdir = findsourcedir(package)
    if not srcdir:
        logging.info("Extracting package : %s", package)
        shutil.unpack_archive("sources/%s.archive" % package, "sources", "gztar")
        srcdir = findsourcedir(package)
