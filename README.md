This repo provides a dockerized buildsystem for freezing python applications in various different linux toolchains.

to build the docker images simply run "bdockerbuild.py" with host python3 interpreter. You can also build a specific image if you provide the target image ie: "python3 dockerbuld.py lunix-armhf"

to build triblerd, simply run "triblerdbuild.py path-to-tribler-source-directory".

The docker images can run in x86 or arm host, or any ISA that QEMU supports, if host is a foreign architecure, the docker will run over QEMU.

Thus images need qemu-user-static needs to be available in your host system to be built.

The pip packages available can easily be scalable by modifiying the dockerfile, or supported cpu architectures can also be extended with available architetures from debian.