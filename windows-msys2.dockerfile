ARG BASE
FROM ${BASE} as builder
ARG THREADS
ENV \
  LANG='C.UTF-8' \
  LC_ALL='C.UTF-8' \
  WINEDEBUG=-all

# install wine >= 5.10
# https://bugs.winehq.org/show_bug.cgi?id=46788,https://github.com/giampaolo/psutil/issues/1448
RUN apt-get update \
    && apt-get install -y \
      apt-transport-https \
      ca-certificates \
      cabextract \
      curl \
      gnupg2 \
      software-properties-common \
      tzdata \
      unzip \
      msitools \
      p7zip-full \ 
      nano \
    && dpkg --add-architecture i386 \
    && curl -sL https://dl.winehq.org/wine-builds/winehq.key | apt-key add - \
    && apt-add-repository "https://dl.winehq.org/wine-builds/debian/ buster main" \
    && curl -sL https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/Debian_10/Release.key | apt-key add - \
    && echo "deb http://download.opensuse.org/repositories/Emulators:/Wine:/Debian/Debian_10 ./" | tee /etc/apt/sources.list.d/wine-obs.list \
    && apt-get update \
    && apt-get install -y winehq-staging=5.10~buster \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -fr /tmp/* \
	&& groupadd group \
    && useradd -m -g group user \
    && usermod -a -G audio user \
    && usermod -a -G video user \
    && chsh -s /bin/bash user \
    && mkdir -p /usr/share/wine/gecko \
    && mkdir -p /work \
    && chown -R user:group /work \
    && chown -R user:group /usr/share/wine/gecko \
    && chown -R user:group /usr/local/bin
    
USER user

# install winetricks and config wine
ARG ARCH1=32
RUN curl -sL -o /usr/local/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
  	&& chmod +x /usr/local/bin/winetricks \
    && WINEARCH=win${ARCH1} wine wineboot \
	&& winetricks -q msls31 \
	&& winetricks -q win7

ENV WINEPATH=/work/mingw64/bin
COPY --chown=user:group sources/msysinstaller.py /work/msysinstaller.py

RUN python3 /work/msysinstaller.py amd64 gcc 8.3.0-1 \
	&& python3 /work/msysinstaller.py amd64 gcc-libs 9.3.0-2 \
	&& python3 /work/msysinstaller.py amd64 gmp 6.2.0-1 \
	&& python3 /work/msysinstaller.py amd64 mpc 1.1.0-1 \
	&& python3 /work/msysinstaller.py amd64 mpfr 4.0.2-2 \
	&& python3 /work/msysinstaller.py amd64 libwinpthread-git 8.0.0.5814.9dbf4cc1-1 \
	&& python3 /work/msysinstaller.py amd64 expat 2.2.9-1 \
	&& python3 /work/msysinstaller.py amd64 bzip2 1.0.8-1 \
	&& python3 /work/msysinstaller.py amd64 libffi 3.3-1 \
	&& python3 /work/msysinstaller.py amd64 mpdecimal 2.4.2-1 \
	&& python3 /work/msysinstaller.py amd64 libsystre 1.0.1-4 \
	&& python3 /work/msysinstaller.py amd64 ncurses 6.2-1 \
	&& python3 /work/msysinstaller.py amd64 ca-certificates 20190110-1 \
	&& python3 /work/msysinstaller.py amd64 libiconv 1.16-1 \
	&& python3 /work/msysinstaller.py amd64 gettext 0.19.8.1-8 \
	&& python3 /work/msysinstaller.py amd64 libtasn1 4.16.0-1 \
	&& python3 /work/msysinstaller.py amd64 p11-kit 0.23.20-1 \
	&& python3 /work/msysinstaller.py amd64 openssl 1.1.1.g-1 \
	&& python3 /work/msysinstaller.py amd64 termcap 1.3.1-5 \
	&& python3 /work/msysinstaller.py amd64 readline 8.0.004-1 \
	&& python3 /work/msysinstaller.py amd64 sqlite3 3.31.1-1 \
	&& python3 /work/msysinstaller.py amd64 tcl 8.6.10-1 \
	&& python3 /work/msysinstaller.py amd64 tk 8.6.10-1 \
	&& python3 /work/msysinstaller.py amd64 zlib 1.2.11-1 \
	&& python3 /work/msysinstaller.py amd64 xz 5.2.5-1 \
	&& python3 /work/msysinstaller.py amd64 libsodium 1.0.18-1 \
	&& python3 /work/msysinstaller.py amd64 python3 3.8.1-2 \
	&& python3 /work/msysinstaller.py amd64 python3-appdirs \
	&& python3 /work/msysinstaller.py amd64 python3-urllib3 \
	&& python3 /work/msysinstaller.py amd64 python3-cachecontrol\
	&& python3 /work/msysinstaller.py amd64 python3-colorama \
	&& python3 /work/msysinstaller.py amd64 python3-contextlib2 \
	&& python3 /work/msysinstaller.py amd64 python3-distlib \
	&& python3 /work/msysinstaller.py amd64 python3-html5lib \
	&& python3 /work/msysinstaller.py amd64 python3-lockfile \
	&& python3 /work/msysinstaller.py amd64 python3-msgpack \
	&& python3 /work/msysinstaller.py amd64 python3-attrs \
	&& python3 /work/msysinstaller.py amd64 python3-packaging \
	&& python3 /work/msysinstaller.py amd64 python3-pep517 \
	&& python3 /work/msysinstaller.py amd64 python3-progress \
	&& python3 /work/msysinstaller.py amd64 python3-pyparsing \
	&& python3 /work/msysinstaller.py amd64 python3-pytoml \
	&& python3 /work/msysinstaller.py amd64 python3-certifi \
	&& python3 /work/msysinstaller.py amd64 python3-chardet \
	&& python3 /work/msysinstaller.py amd64 python3-idna \
	&& python3 /work/msysinstaller.py amd64 python3-requests \
	&& python3 /work/msysinstaller.py amd64 python3-retrying \
	&& python3 /work/msysinstaller.py amd64 python3-six \
	&& python3 /work/msysinstaller.py amd64 python3-webencodings \
	&& python3 /work/msysinstaller.py amd64 python3-pip
# install winpython + pip

ARG MSYS2_PYTHON_URL=http://repo.msys2.org/mingw/x86_64/mingw-w64-x86_64-python3-3.8.1-2-any.pkg.tar.xz
ARG ARCH3
RUN cd /work \
	&& curl -L ${MSYS2_PYTHON_URL} -o python.tar.xz \
	&& tar -xf python.tar.xz \
	&& rm -f python.tar.xz

# patch mingwcompiler to work with wine
#COPY --chown=user:group sources/patches/cygwinccompiler.pywin /work/python/Lib/distutils/cygwinccompiler.py

RUN cd /work \
	&& curl -L http://repo.msys2.org/mingw/x86_64/mingw-w64-x86_64-gcc-8.3.0-1-any.pkg.tar.xz -o target.tar.xz \
	&& tar -xf target.tar.xz \
	&& rm -f target.tar.xz

COPY --chown=user:group sources /home/sources

# install precompiled libsodium
ARG LIBSODIUM_VER
RUN cd /work \
	&& curl -L http://repo.msys2.org/mingw/x86_64/mingw-w64-x86_64-libsodium-${LIBSODIUM_VER}-1-any.pkg.tar.xz -o target.tar.xz \
	&& tar -xf target.tar.xz \
	&& rm -f target.tar.xz

# patch mingwcompiler to work with wine
COPY --chown=user:group sources/patches/cygwinccompiler.pywin /work/python/Lib/distutils/cygwinccompiler.py

# b2 batch scripts does not understand wine environemt, so we compile them like a macho man :)
ARG BOOST_SRC
RUN cd /home/sources \
	&& curl -L https://github.com/boostorg/build/archive/4.2.0.zip -o boostbuild.zip \
	&& unzip boostbuild.zip \
	&& cd build-4.2.0/src/engine \
	&& wine cmd /c g++ -x c++ -std=c++11 -static-libstdc++ -s -O3 -o b2.exe -DNDEBUG \
		builtins.cpp class.cpp command.cpp compile.cpp constants.cpp cwd.cpp debug.cpp \
		debugger.cpp execcmd.cpp execnt.cpp filent.cpp filesys.cpp frames.cpp function.cpp \
		glob.cpp hash.cpp hcache.cpp hdrmacro.cpp headers.cpp jam.cpp jambase.cpp jamgram.cpp \
		lists.cpp make.cpp make1.cpp md5.cpp mem.cpp modules.cpp native.cpp object.cpp option.cpp \
		output.cpp parse.cpp pathnt.cpp pathsys.cpp regexp.cpp rules.cpp scan.cpp search.cpp \
		jam_strings.cpp subst.cpp sysinfo.cpp timestamp.cpp variable.cpp w32_getreg.cpp modules/order.cpp \
		modules/path.cpp modules/property-set.cpp modules/regex.cpp modules/sequence.cpp modules/set.cpp \
	&& cp b2.exe ${BOOST_SRC}/

# compile libtorrent with gcc + wine
ARG LIBTORRENT_SRC
RUN	cd ${BOOST_SRC} \
	&& cp /home/sources/patches/project-config.boostwin ${BOOST_SRC}/project-config.jam \
	&& cp /home/sources/patches/builtin_converters.boost ${BOOST_SRC}/libs/python/src/converter/builtin_converters.cpp \
	&& cp /home/sources/patches/project-config.ltwin ${LIBTORRENT_SRC}/bindings/python/project-config.jam \
	&& cp /home/sources/patches/Jamfile.lt ${LIBTORRENT_SRC}/Jamfile \
	&& cp /home/sources/patches/Jamfile.pylt ${LIBTORRENT_SRC}/bindings/python/Jamfile \
	&& cp /home/sources/patches/rss.cpp.lt ${LIBTORRENT_SRC}/src/rss.cpp \
	&& cd ${LIBTORRENT_SRC}/bindings/python/ \
	&& wine ${BOOST_SRC}/b2.exe -sBOOST_ROOT=Z:\\home\\sources\\boost_1_65_0 variant=release link=shared runtime-link=shared boost-link=shared libtorrent-link=shared -j8 \
	&& cp ${BOOST_SRC}/bin.v2/libs/chrono/build/gcc-*/release/boost-link-shared/threading-multi/*.dll /work/python/DLLs/ \
	&& cp ${BOOST_SRC}/bin.v2/libs/random/build/gcc-*/release/boost-link-shared/threading-multi/*.dll /work/python/DLLs/ \
	&& cp ${BOOST_SRC}/bin.v2/libs/system/build/gcc-*/release/boost-link-shared/threading-multi/*.dll /work/python/DLLs/ \
	&& cp ${BOOST_SRC}/bin.v2/libs/python/build/gcc-*/release/boost-link-shared/*.dll /work/python/DLLs/ \
	&& cp ${LIBTORRENT_SRC}/bin/gcc-*/release/boost-link-shared/threading-multi/*.dll /work/python/DLLs/ \
	&& cp ${LIBTORRENT_SRC}/bindings/python/bin/gcc-*/release/boost-link-shared/lt-visibility-hidden/*.pyd /work/python/DLLs/

# get upx
RUN cd /home/sources \
	&& curl -L https://github.com/upx/upx/releases/download/v3.96/upx-3.96-win${ARCH1}.zip -o upx.zip\
	&& unzip upx.zip \
	&& cp upx-3.96-win${ARCH1}/upx.exe ~/.wine/drive_c/windows/system32/ \
	&& rm -rf upx*

# install pypa packages
# pyinstaller 3.5 has issue: https://github.com/pyinstaller/pyinstaller/issues/4265
# pyinstaller 3.6 has issue: https://github.com/pyinstaller/pyinstaller/issues/4628
# thus we use a version in the middle: commit 9dd34bdfbaeaa4e0459bd3051d1caf0c7d75073f
ARG CRYPTOGRAPHY_VER	
RUN wine /work/python/python -m pip install \ 
	lz4 \
	cryptography==${CRYPTOGRAPHY_VER} \
	PyWin32 \
	wheel \
	chardet \
	decorator \
	dnspython \
	ecdsa \
	feedparser \
	jsonrpclib \
	networkx \
	pony \
	protobuf \
	psutil \
	pyaes \
	pyasn1 \
	pysocks \
	requests \
	PyOpenSSL \
	libnacl \
	service_identity \
	aiohttp \
	aiohttp_apispec \
	pyyaml \
	marshmallow \
	asynctest \
	nose \
	pbkdf2 \
	configobj \
	&& wine /work/python/python -m pip install --global-option build_ext --global-option --compiler=mingw32 \ 
	https://github.com/pyinstaller/pyinstaller/archive/9dd34bdfbaeaa4e0459bd3051d1caf0c7d75073f.zip \
	netifaces
USER root
# clean system
RUN python3 /home/sources/cleandeb.py winehq-staging apt e2fsprogs fdisk base-passwd \
	&& ./cleandeb.sh \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /home/sources \
	&& rm -rf /tmp/* \
	&& rm -fr /home/user/tmp/* \
	&& rm -fr /home/user/.cache/*

FROM scratch
COPY --from=builder / /
WORKDIR /work
USER user
ENV \
  LANG='C.UTF-8' \
  LC_ALL='C.UTF-8' \
  WINEDEBUG=-all \
  WINEPATH=/work/mingw/bin
CMD /bin/bash
