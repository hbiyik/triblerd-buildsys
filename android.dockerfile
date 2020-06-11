ARG BASE
FROM ${BASE} 
RUN mkdir -p /usr/share/man/man1 && \
	apt-get update && apt-get install -y -q \
    build-essential \
    sudo \
    bsdtar \
    git \
    zip \
    ffmpeg \
    libssl-dev \
    libsdl2-dev \
    libsdl2-image-dev \
    libsdl2-mixer-dev \
    libsdl2-ttf-dev \
    libportmidi-dev \
    libswscale-dev \
    libavformat-dev \
    libavcodec-dev \
    zlib1g-dev \
    libgstreamer1.0 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    libgstreamer1.0-dev \
    openjdk-11-jdk \
    ccache \
    unzip \
    wget \
    lld \
    clang \
    autoconf \
    libtool \
    pkg-config \
    libncurses5-dev \
    libncursesw5-dev \
    libtinfo5 \
    cmake \
    libffi-dev \
    libssl-dev && \
	python3.7 -m pip install --trusted-host pypi.python.org Cython Pillow Kivy buildozer
COPY packages.json /work/packages.json
COPY buildozer /work/buildozer
RUN	set -ex \
    && useradd kivy -mN \
    && echo "kivy:kivy" | chpasswd \
    && chown -R kivy:users /work
USER kivy
RUN cd /work/buildozer && \
	python3 alterspec.py app:requirements=triblerdeps && \
	python3 alterspec.py app:android.arch=armeabi-v7a && \
	buildozer android release  && \
	rm -rf /work/buildozer/bin && \
	rm -rf /work/buildozer/dist
RUN cd /work/buildozer && \
	python3 alterspec.py app:android.arch=arm64-v8a && \
	buildozer android release && \
	rm -rf /work/buildozer/bin && \
	rm -rf /work/buildozer/dist
RUN cd /work/buildozer && \
	python3 alterspec.py app:android.arch=x86 && \
	buildozer android release && \
	rm -rf /work/buildozer/bin && \
	rm -rf /work/buildozer/dist
RUN cd /work/buildozer && \
	python3 alterspec.py app:android.arch=x86_64 && \
	buildozer android release && \
	rm -rf /work/buildozer/bin && \
	rm -rf /work/buildozer/dist