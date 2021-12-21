ARG BASE
FROM ${BASE} as builder
ARG QEMU_STATIC
ARG THREADS
COPY ${QEMU_STATIC} /usr/bin
RUN apt-get update && \
	apt-get purge -y ".+\-dev" || true && \
	apt-get purge -y "libsqlite*" || true && \
	apt-get autoremove -y && \
	apt-get install -y gcc g++ make libc-dev zlib1g-dev \
	libncurses5-dev libncursesw5-dev libreadline-dev libbz2-dev libexpat1-dev \
	uuid-dev libgmp3-dev libffi-dev libgdbm-dev upx
COPY sources /home/sources
ARG PERL_SRC
RUN cd ${PERL_SRC} && \
	sh Configure -des && \
	make -j${THREADS} && \
	make install
ARG OPENSSL_SRC
ARG OPENSSL_PLATFORM
ARG OPENSSL_ARG1
ARG OPENSSL_ARG2
RUN cd ${OPENSSL_SRC} && \
	./Configure ${OPENSSL_PLATFORM} ${OPENSSL_ARG1} ${OPENSSL_ARG2} shared && \
	make -j${THREADS} && \
	cp ${OPENSSL_SRC}/lib*.so* /usr/lib/ && \
	cp -rf ${OPENSSL_SRC}/include/openssl /usr/include/
ARG LIBSODIUM_SRC
RUN cd ${LIBSODIUM_SRC} && \
	./configure --prefix=/usr && \
	make -j${THREADS} && \
	make install
ARG SQLITE_SRC
RUN cd ${SQLITE_SRC} && \
	./configure --prefix=/usr && \
	make -j${THREADS} && \
	make install
ENV SSL_CERT_FILE=/etc/rootcert.pem
ARG PYVER
ARG PYTHON_SRC
RUN cd ${PYTHON_SRC} && \
 	ln -s /usr/include/*-linux-*/*.h /usr/include/ && \
 	cp /home/sources/patches/semaphore.pymp ${PYTHON_SRC}/Modules/_multiprocessing/semaphore.c && \
 	cp /home/sources/patches/Makefile.pre.pyin ${PYTHON_SRC}/Makefile.pre.in && \
	./configure --with-system-ffi --enable-shared && \
	make -j${THREADS} && make -j1 install && \
	cp libpython*.so* /usr/lib/ && \
	python${PYVER} -m pip install --upgrade pip && \
	python${PYVER} -m pip install --upgrade certifi && \
	ln -s $(python${PYVER} -c 'import certifi; print(certifi.where())') /etc/rootcert.pem
ARG BOOST_SRC
ARG LIBTORRENT_SRC
RUN cd ${BOOST_SRC} && ./bootstrap.sh && \
	cp /home/sources/patches/project-config.boost ${BOOST_SRC}/project-config.jam && \
	cp /home/sources/patches/builtin_converters.boost ${BOOST_SRC}/libs/python/src/converter/builtin_converters.cpp && \
	cp /home/sources/patches/project-config.lt ${LIBTORRENT_SRC}/bindings/python/project-config.jam && \
	cp /home/sources/patches/Jamfile.lt ${LIBTORRENT_SRC}/Jamfile && \
	cp /home/sources/patches/Jamfile.pylt ${LIBTORRENT_SRC}/bindings/python/Jamfile && \
	cp /home/sources/patches/rss.cpp.lt ${LIBTORRENT_SRC}/src/rss.cpp && \
	cd ${LIBTORRENT_SRC}/bindings/python/ && \
	BOOST_ROOT=${BOOST_SRC} ${BOOST_SRC}/b2 variant=release -j8 && \
	cp ${BOOST_SRC}/bin.v2/libs/chrono/build/gcc-*/release/libtorrent-python-pic-on/threading-multi/*.so* /usr/lib/ && \
	cp ${BOOST_SRC}/bin.v2/libs/python/build/gcc-*/release/*.so* /usr/lib/ && \
	cp ${BOOST_SRC}/bin.v2/libs/random/build/gcc-*/release/libtorrent-python-pic-on/threading-multi/*.so* /usr/lib/ && \
	cp ${BOOST_SRC}/bin.v2/libs/system/build/gcc-*/release/libtorrent-python-pic-on/threading-multi/*.so* /usr/lib/ && \
	cp ${LIBTORRENT_SRC}/bin/gcc-*/release/libtorrent-python-pic-on/threading-multi/*.so* /usr/lib/ && \
	cp ${LIBTORRENT_SRC}/bindings/python/bin/gcc-*/release/libtorrent-python-pic-on/lt-visibility-hidden/*.so* /usr/local/lib/python${PYVER}/site-packages/
ARG CRYPTOGRAPHY_SRC
RUN	python${PYVER} -m pip install -v --no-binary :all: pycparser cffi && \
	cp /home/sources/patches/osrandom_engine.cry ${CRYPTOGRAPHY_SRC}/src/_cffi_src/openssl/src/osrandom_engine.c && \
	cd ${CRYPTOGRAPHY_SRC} && python${PYVER} setup.py install && \
	python${PYVER} -m pip install -v \
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
	yappi==1.3.3 \
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
USER root
# clean system
RUN python3 /home/sources/cleandeb.py gcc g++ make libc-dev zlib1g-dev \
	libncurses5-dev libncursesw5-dev libreadline-dev libbz2-dev libexpat1-dev \
	uuid-dev libgmp3-dev libffi-dev libgdbm-dev upx upx-ucl apt apt-get apt-cache e2fsprogs fdisk base-passwd \
	&& ./cleandeb.sh \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /home/* \
    && userdel pi || true \
    && groupdel pi || true \
    && groupadd group \
    && useradd -m -g group user \
    && chsh -s /bin/bash user \
    && mkdir -p /work \
    && chown -R user:group /work \
	&& rm -rf /tmp/* \
	&& rm -fr /home/user/tmp/* \
	&& rm -fr /home/user/.cache/* \
	&& rm -fr /root/.cache/*

FROM scratch
COPY --from=builder / /
WORKDIR /work
USER user
CMD /bin/bash
