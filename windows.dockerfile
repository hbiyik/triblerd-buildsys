ARG BASE
FROM debian:buster-slim@sha256:7c459309b9a5ec1683ef3b137f39ce5888f5ad0384e488ad73c94e0243bc77d4 as builder
ARG THREADS
ENV \
  LANG='C.UTF-8' \
  LC_ALL='C.UTF-8' \
  WINEDEBUG=-all

# install wine + winetricks
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
      python \
      msitools \
      python-simplejson \
      python-six \
      p7zip-full \ 
      nano \
    && dpkg --add-architecture i386 \
    && curl -sL https://dl.winehq.org/wine-builds/winehq.key | apt-key add - \
    && apt-add-repository "https://dl.winehq.org/wine-builds/debian/ buster main" \
    && curl -sL https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/Debian_10/Release.key | apt-key add - \
    && echo "deb http://download.opensuse.org/repositories/Emulators:/Wine:/Debian/Debian_10 ./" | tee /etc/apt/sources.list.d/wine-obs.list \
    && apt-get update \
    && apt-get install -y winehq-stable \
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

ARG GECKO_VER=2.47.1

RUN curl -sL -o /usr/share/wine/gecko/wine-gecko-${GECKO_VER}-x86.msi "https://dl.winehq.org/wine/wine-gecko/${GECKO_VER}/wine-gecko-${GECKO_VER}-x86.msi" \
    && curl -sL -o /usr/local/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
  	&& chmod +x /usr/local/bin/winetricks \
    && WINEARCH=win32 wine wineboot \
	&& winetricks -q msls31 \
	&& winetricks -q ole32 \
	&& winetricks -q riched20 \
	&& winetricks -q riched30 \
	&& winetricks -q win7 \
	&& rm -fr /home/user/.cache/* \
	&& rm -fr /home/user/tmp/*

# install embedded python + pip
RUN mkdir -p /work/i386 \
	&& cd /work/i386 \
	&& curl -L https://github.com/winpython/winpython/releases/download/2.2.20191222/Winpython32-3.8.1.0dot.exe -o winpython.exe \
	&& wine winpython.exe -o"winpythontemp" -y & sleep 10 \
	&& cd /work/i386 \
	&& mv winpythontemp/WPy32-3810/python-3.8.1 python \
	&& rm -rf winpythontemp winpython.exe \
	&& wine python/python.exe -m pip install pip --upgrade \
	&& cp /opt/wine-stable/lib/wine/vcruntime140.dll /work/i386/python/libs/

COPY sources/patches/cygwinccompiler.pywin /work/i386/python/Lib/distutils/cygwinccompiler.py

RUN cd /work/i386 \
	&& curl -L https://netcologne.dl.sourceforge.net/project/mingw-w64/Toolchains%20targetting%20Win32/Personal%20Builds/mingw-builds/8.1.0/threads-win32/dwarf/i686-8.1.0-release-win32-dwarf-rt_v6-rev0.7z -o mingw.7z \
	&& 7z x mingw.7z \
	&& rm -f mingw.7z

ENV WINEPATH="/work/i386/mingw32/bin"

# install pypa packages	
RUN wine /work/i386/python/python.exe -m pip install \
	wheel \
	bitcoinlib \
	chardet \
	decorator \
	dnspython \
	ecdsa \
	feedparser \
	jsonrpclib \
	networkx \
	pony \
	protobuf psutil \
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
	PyInstaller \
	nose \
	lz4 \
	cryptography==2.8 \
	pbkdf2 \
	configobj \
	&& wine /work/i386/python/python -m pip install --global-option build_ext --global-option --compiler=mingw32 netifaces
