ARG BASE
FROM ${BASE} as builder
ARG THREADS
ENV \
  LANG='C.UTF-8' \
  LC_ALL='C.UTF-8' \
  WINEDEBUG=-all

# install wine >= 5.10
# https://bugs.winehq.org/show_bug.cgi?id=46788,https://github.com/giampaolo/psutil/issues/1448
RUN apt-get update && apt-get install -y apt-transport-https ca-certificates cabextract curl gnupg2 \
      software-properties-common tzdata unzip msitools p7zip-full nano \
    && dpkg --add-architecture i386 \
    && curl -sL https://dl.winehq.org/wine-builds/winehq.key | apt-key add - \
    && apt-add-repository "https://dl.winehq.org/wine-builds/debian/ buster main" \
    && curl -sL https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/Debian_10/Release.key | apt-key add - \
    && echo "deb http://download.opensuse.org/repositories/Emulators:/Wine:/Debian/Debian_10 ./" | tee /etc/apt/sources.list.d/wine-obs.list \
    && apt-get update \
    && apt-get install -y winehq-staging \
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

# install winpython + pip
ARG WINPYTHON_URL=https://github.com/winpython/winpython/releases/download/2.2.20191222/Winpython${ARCH1}-3.8.1.0dot.exe
ARG ARCH3
RUN cd /work \
	&& curl -L ${WINPYTHON_URL} -o winpython.exe \
	&& wine winpython.exe -o"winpythontemp" -y & sleep 20 \
	&& cd /work \
	&& mv winpythontemp/WPy${ARCH1}-3810/python-3.8.1${ARCH3} python \
	&& rm -rf winpythontemp winpython.exe \
	&& wine python/python.exe -m pip install pip --upgrade \
	&& cp /work/python/vcruntime140.dll /work/python/libs/

# patch mingwcompiler to work with wine
COPY --chown=user:group sources/patches/cygwinccompiler.pywin /work/python/Lib/distutils/cygwinccompiler.py

# install mingw
ARG MINGW
ARG MINGW_URL=https://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win${ARCH1}/Personal%20Builds/mingw-builds/7.3.0/threads-posix/${MINGW}

RUN cd /work \
	&& curl -L ${MINGW_URL} -o mingw.7z \
	&& 7z x mingw.7z \
	&& rm -f mingw.7z \
	&& mv mingw${ARCH1} mingw \
	&& cp /work/mingw/bin/*.dll /work/python/DLLs/

ENV WINEPATH=/work/mingw/bin

COPY --chown=user:group sources /home/sources

# install precompiled libsodium
ARG LIBSODIUM_VER
ARG ARCH4
RUN cd /home/sources \
	&& curl -L https://github.com/jedisct1/libsodium/releases/download/1.0.18-RELEASE/libsodium-1.0.18-msvc.zip -o libsodium.zip \
	&& unzip libsodium.zip \
	&& cp libsodium/${ARCH4}/Release/v141/dynamic/libsodium.dll ~/.wine/drive_c/windows/system32/libsodium.dll \
	&& rm -rf libsodium*

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
# use old version of setuptools (should be <= 59.0.1) for yappi which does not push ucrt lib in mingw32 compiler
RUN wine /work/python/python -m pip install -v --global-option build_ext --global-option --compiler=mingw32 yappi==1.3.3 && \
	wine /work/python/python -m pip install setuptools -U && \
	wine /work/python/python -m pip install -v \ 
	aiohttp==3.8.1 \
	aiohttp-apispec==2.2.1 \
	anyio==3.3.4 \
	chardet==4.0.0 \
	configobj==5.0.6 \
	decorator==5.1.0 \
	Faker==9.8.2 \
	libnacl==1.8.0 \
	lz4==3.1.3 \
	marshmallow==3.14.1 \
	netifaces==0.11.0 \
	networkx==2.6.3 \
	pony==0.7.14 \
	psutil==5.8.0 \
	pyasn1==0.4.8 \
	pydantic==1.8.2 \
	PyOpenSSL==21.0.0 \
	pyyaml==6.0 \
	sentry-sdk==1.5.0 \
	service-identity==21.1.0 \
	PyInstaller==4.2 \
	pytest==6.2.5 \
	pytest-aiohttp==0.3.0 \
	pytest-asyncio==0.16.0 \
	pytest-cov==3.0.0 \
	pytest-mock==3.6.1 \
	pytest-randomly==3.10.2 \
	pytest-timeout==2.0.1 \
	pytest-xdist==2.4.0 \
	pytest-freezegun==0.4.2 \
	freezegun==1.1.0 \
	asynctest==0.13.0
	# https://github.com/pyinstaller/pyinstaller/archive/9dd34bdfbaeaa4e0459bd3051d1caf0c7d75073f.zip
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
