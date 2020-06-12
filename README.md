### What is this and why do we need such a thing?

This repo provides a dockerized system that can build tribler daemon, into various operating systems and toolchains. This build system is useful because:

- Each and every non-python dependency of the tribler can be harmonized with the same source code and build variables
- Each build for each target will have the exact same binary output regardless of development environment.
- The dependencies of of the binary generated for the target platform will be vastly supported in the deployment devices (target life-cycle is last 10 years)
- Not only building the production binaries but also running the unit tests in the foreign targets and running the actual applications in the target
- Target specific optmizations can be enabled in the source code. Ie: OpenSSL has great set of assembly level optimization for each cpu instruction set. This buildsystem leverages this
- Tribler is a distributed app, but the problem is in today world, an app only for desktop is practically a very restricted user base which cripples the suer base of the application. The modile devices and HTPCs Set top boxes must also be targeted.
- It is laso targetted to have IPV8 to be ported on a native language like Rust, so when this step came in, portability of tribler source also must be assured, this system also assures this as well. 

### Ok Cool, so how does this work?

There are actually 2 ways to compile the source code to foreign target, 1st is to compile the source code in an emulated environment of your target, and 2nd one is compiling the code to the foreign environment on the host environment with a cross compiler. Even though cross compiling is fast and versatile way of handling things, the python freezing module that is used in tribler (PyInstaller) does not officially support cross compiling. So in the minimum at least the python interpreter that is compiled for the target system, must be run in an emulated environment so that python code and the target compiled binaries can be frozen with PyInstaller. This buildysytem uses QEMU for for emulated environment in Docker on linux, and buildozer (P4A) system fro cross compiling to android.

Each and every dependency is build for the target and stored in a docker container, then the Python code for tribler is froyen with this docker without compiling the dependencies from scratch. The building of images can take a long while which is not a problem since they will be built once, and the actual freezing (packaging the tribler) process is generally done in minutes, which is quite fast.

### How is the backwards compatibility and what is that toolchain thing?
 Toolchain dependencies (in the sense i will use in this context to prevent philosophical discussions) is to sum of the dependencies of the generated binaries. They can be either hardware variations or software variations.
 
**1.Hardware Variants & Features**
**1.1. Target CPU Instruction Set Architecture (ISA):** 
- Intel X86 32bit (Supported: i386)
- Amd X86 64 bit (Supported: amd64)
- Armv5 ISA (Supported: armel)
- Armv6 ISA (Supported: armel) 
- Armv7 ISA (Supported: armhf)
- Armv8 32/64bit ISA (Supported: aarch64)
- Mips / Mipsel, Sparc, s390, ia64, powerpc, s390, s390x (Not supported but can easily be extended for linux be using debian dockers. see: https://wiki.debian.org/DebianWheezy)
	
**1.2. Co-processor Variants:**
Co processor is a hardware extension to the CPU where the main CPU (ALU) can pass some certain task to it, so they can be performed more efficiently and and faster. For x86 architecture, co-processors are defined by the architecture itself (ie: MMX, SSE ie See: https://en.wikipedia.org/wiki/X86#Extensions) so they dont create a dependency but for ARM they are a dependency. (see: https://image.slidesharecdn.com/eurollvm-2016-arm-code-size-160318212149/95/a-close-look-at-arm-code-size-6-638.jpg) 
- VFPUv2 >= armv5 (not supported, use soft floting point armel variant)
- VFPUv3 >= armv7 (armhf supports armv7 ISA together with VFPUv3 floating point built binaries)
- NEON >= armv7 (armhf for armv7 ISA, aarch64 for armv8)
- CRYPTO >= armv8 (supported in ararch64)
	
If your software dependencies are compiled without co-processor extension, but your main binary is, then you can not run your software in this ABI (application binary interface), BUT if your dependency is compiled with co-processor extension but your binary is not, then you can run your binary in this ABI.
	
Raspberry PI-0/1 is a good example for this, the armv6 cpu in PI-0/1 has a VFPUv2, and armel toolchain does not has VFPU extensions enabled, the binaries generated with armel can run in PI0/1 regardless if the os is using hard float or not. But note that, there is a speed penalty with armel toolchain since all the floating point operation are handled in the ALU instead of VFPU.
	
Or for raspberry PI2 the CPU has armv7 ISA with VFPUv3 co-processor. If the software dependency is built with FPUv3 enabled, then the armhf toolchain must be used, but even though the cpu is VFPUv3 compatible, if the OS is not compiled with VFPUv3 compatibility then armel toolchain must be used.
	
**1.3. CPU Endianness:**
CPUs may interpret the byte code LSB first MSB first. For the cpu types which uses one Endieannes the is no issue, but for the cpus which supports both, all your software dependencies must be in the same Endianness. Even though this is a case for ARM & Mips, in arm world Little Endiann is more like a defacto standart, if an os is using Big Endian with it is either a fancy experimental thing, or a commercial device which depends on a closed source binary with big endian (like device driver).

- Big Endiann (Not supported)
- Little Endian  (Everthing is little endian here)

**2. Software Dependencies:**
**2.1. The Kernel**
In linux kernels, software projects generally (unless they are very special or driver) don't directly interact with linux kernel for standard operation, instead the C library does that for us, however in windows it is possible to interact directly not with kernel but windows libraries, we will not go through this route. All of the dependencies in this build system is using a C library to interact with the kernel.
- Windows: (not supported yet but can be extended with wine + cross compilers)
- Linux: Supported
- Android: Supported
	
**2.2. The C Library**
**2.2.1 GNU C Library (Supported):**
	In linux for most of the distros or custom OSes the C library is GNU C library. The GNU C library is only backwards compatible not forward compatible, if the system glibc library in 2.5, but your binary is compiled with 2.30 the binary will work fine. But the vice verse is not possible. The approach in this build-system is to use the oldest GNUC library for the CPU target which was released. Ie: For i386 target, glibc version is 2.7 but for aarch64 2.20. This is ok because arm64 was introduced to the market around those years, so there is no practical point to have glic2.5 compatibility for aarch64
	
**2.2.2. uC Library: (Not Supported)**
GNUc library is great for daily systems but for embedded systems the lib size may be sometimes big, for this reason there are several different C libraries which can do almost everything with a restricted scope. MicroC library is the most common of them which is mainly used in embedded devices. This buildsystem does not support uclibc but in future may be extended with few effort. There actually a use case for this for instance like running tribler daemon inside a router or a switch (Openwrt/DD-WRT or most of the commercial routers us uclibc variants). However storage size and cpu capabilities may be a concern. Also worth to mention that there is also 0.x, 1.x version od uclibc with only backwards compatibility.
	
**2.2.3. Musl: (Not Supported)**
Same as uclibc.
	
**2.2.4. Bionic C:**
Bionic C library is the C library of android, the forward compatibility of of android ndk is api version 21 (5.0 Lollipop: https://en.wikipedia.org/wiki/Android_version_history#Android_5.0_Lollipop_(API_21)). The limitation is due to python interpreter, it can be improved to have lower api compatibility if necessary.
	
**2.3. The C++ Library: (Not Relevant)**
Even though this is a dependency, each freezing app (PyInstaller, P4A) compiles its own cpp library and bundles it with the package, so the app will not depend on system cpp libraries.
	
**2.4. The Compiler (GCC):**
You may think how come the compiler itself is relevant but it is in the case GCC. GCC sometimes changes the ABI that it uses in the creation of the binaries, and this change is only backwards compatible, so gcc with the lowest version must be used. Current buildsys uses version down to 4.3 which is very very old, and sometimes the source code must be patched to support for this compiler (ie: python cryptography module or libtorrent itself. But using this kind of old version of GCC is a design choice.
	
	
### So what targets does this build system support?:
- **linux-i386:** practically for any linux distro released more than 10 years ago that that runs on a x64 cpu etiher in 32bit or 64 bit mode
- **linux-amd64:** same as above but only in 64 bit mode, with better performance and assembly level optimizations
- **linux-armel:** very old arm based linux distros down to >= armv5
- **linux-armhf:** most arm7 based devices and linux devices regardless of what kind of SOC it is.
- **linux-aarch64:** nearly all distros with armv8 SOCs.
- **android-i386:** atom based devices with Android >= 5.0 Lollipop
- **android-amd64:** atom based devices with Android >= 5.0 Lollipop in 64bit mode
- **android-armhf:** all android devices with arm>=v7 and Android >=5.0 Lollipop 
- **android-aarch64:** all android devices with arm>=v8 and Android >=5.0 Lollipop

Those tooolchains above basically cover more than %95 of the devices with linux and android osses.

### How can I use this?
Even though the system is base don docker images, you don't have to deal with finicky docker commands, everything is automated through python scripts

**Prerequisites:**
1. If you want to use the system in emulation mode, you must have a x86 64bit windows, otherwise you can only use the containers in the native architecture.
2. Install docker & python3 to your system.

**Configure:**

    python3 configure.py

this script will automatically download all the necessary software packages from the internet. There is not arguments for this tool. Without running configure, you can not run rest of the scripts, this is mandatory at least once.

**Make docker images:**

    python3 makedocker.py

After you initiated configure, you can run above command to build the docker images for all targets. If you do not provide any arguments the script will build all available targets and this will take a lot of time, several hours. So leave your computer as is, and open your ventialtion, because your cpu will heat a lot for the next few hours.

    python3 makedocker.py help

run this command to see available docker images to build

    python3 makedocker.py linux-amd64

run the script for a specific image name if you want to build the image only for 1 specific image instead of all of them.


**Build triblerd**

to build triblerd you should have built the docker images already, if you havent build the docker images first

    python3 maketriblerd.py --srcdir=pathtotriblersourcedir

above command will build tribler for all available targets, maketriblerd.py requires at least --srcdir argument that points to the tribler source dir. The path can be either relative or absolute path

    python3 maketriblerd.py --srcdir=pathtotriblersourcedir --target=linux-amd64

if you provide --target argument the build will only be made for the specific target

    python3 maketriblerd.py --srcdir=pathtotriblersourcedir --target=linux-amd64 --debugrun

above command will directly run your current triblerd application in the target docker, this way you can easily verify your system is working as expected or not

    python3 maketriblerd.py --srcdir=pathtotriblersourcedir --target=linux-amd64 --test

above command will run the unit tests in the target environment. This is very useful for checking the problems in your target system. --debugrun and --test flags are also valid for android as well.

**Testing and running in android:**

unlike linux target, running and testing requires an actual device attached to your pc. Enable the usb debugging and stay awake options in the android device that you plugged in the usb of your pc and run.

    adb devices

this should provide 1 device with a proper authorization, the run

    adb shell

command to verify that your pc does not have any problem on usb debugging of your android device. If you have problems in your host pc running above commands, then android --debugrun or --test wont work in buildsystem as well.

if everything went smooth run

    python3 maketriblerd.py --srcdir=pathtotriblersourcedir --target=android-armhf --debugrun

for running your app on target android device

    python3 maketriblerd.py --srcdir=pathtotriblersourcedir --target=android-armhf --test

for running the unittests

*PS: make sure your android CPU architecture maches.*

**Q&A:**
**Q.** Why there is a custom test runner instead of using nose or some already available test runner
**A.** P4A compiles the python source file to .pyo and nose can not execute the tests unless there is actually a .py file. the custom testrunner.py can execute .pyc files.

**Q.** Is it possbile to build other app with this
**A.** Yes the system is very versatile and can be extended with any more dependencies

**Q.** The main file for android is very limited
**A.** Android kivy app is just a place holder, a seperate kivy app should be developed. Since the core is running, the app may only utilize the android ui and core service. 