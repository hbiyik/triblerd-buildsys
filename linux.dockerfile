ARG BASE
FROM ${BASE} as builder
ARG QEMU_STATIC
ARG THREADS
COPY ${QEMU_STATIC} /usr/bin
COPY sources /home/sources
RUN apt-get update && apt-get install -y gcc g++ make libc-dev zlib1g-dev \
	libncurses5-dev libncursesw5-dev libreadline-dev libbz2-dev libexpat1-dev \
	uuid-dev libgmp3-dev libffi-dev libgdbm-dev upx
ARG PERL_SRC
RUN cd ${PERL_SRC} && \
	sh Configure -des && \
	make -j${THREADS} && \
	make install
ARG OPENSSL_SRC
ARG OPENSSL_PLATFORM
RUN cd ${OPENSSL_SRC} && \
	./Configure ${OPENSSL_PLATFORM} shared && \
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
	./configure --with-system-ffi --enable-shared && \
	make -j${THREADS} && make install && \
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
RUN	python${PYVER} -m pip install --no-binary :all: pycparser cffi && \
	cp /home/sources/patches/osrandom_engine.cry ${CRYPTOGRAPHY_SRC}/src/_cffi_src/openssl/src/osrandom_engine.c && \
	cd ${CRYPTOGRAPHY_SRC} && python${PYVER} setup.py install && \
	python${PYVER} -m pip install --no-binary :all: wheel bitcoinlib chardet configobj decorator dnspython \
	ecdsa feedparser jsonrpclib netifaces networkx pbkdf2 pony protobuf psutil \
	pyaes pyasn1 pysocks requests PyOpenSSL libnacl service_identity \
	networkx aiohttp aiohttp_apispec pyyaml marshmallow netifaces asynctest PyInstaller nose && \
	python${PYVER} -m pip install --no-binary :all: lz4
FROM ${BASE}
COPY --from=builder /usr /usr