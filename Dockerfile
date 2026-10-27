FROM ubuntu:22.04 AS build

ENV DEBIAN_FRONTEND=noninteractive

ARG CHOOCHOO_REF=45f2131c603b52afc837637de9874b6b59f9eb3f

RUN dpkg --add-architecture arm64 \
    && rm -f /etc/apt/sources.list /etc/apt/sources.list.d/ubuntu.sources \
    && printf '%s\n' \
        'deb [arch=amd64] http://archive.ubuntu.com/ubuntu jammy main restricted universe multiverse' \
        'deb [arch=amd64] http://archive.ubuntu.com/ubuntu jammy-updates main restricted universe multiverse' \
        'deb [arch=amd64] http://archive.ubuntu.com/ubuntu jammy-backports main restricted universe multiverse' \
        'deb [arch=amd64] http://security.ubuntu.com/ubuntu jammy-security main restricted universe multiverse' \
        > /etc/apt/sources.list \
    && printf '%s\n' \
        'deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports jammy main restricted universe multiverse' \
        'deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports jammy-updates main restricted universe multiverse' \
        'deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports jammy-backports main restricted universe multiverse' \
        'deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports jammy-security main restricted universe multiverse' \
        > /etc/apt/sources.list.d/arm64.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        make \
        build-essential \
        g++-aarch64-linux-gnu \
        pkg-config \
        zip \
        libsdl2-dev:arm64 \
        libasound2-dev:arm64 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

RUN git clone --no-checkout \
    https://github.com/paiheulevrai/Choochootracker.git /workspace/Choochootracker \
    && cd /workspace/Choochootracker \
    && git checkout --detach "${CHOOCHOO_REF}" \
    && git submodule update --init --recursive

RUN sed -i 's/\r$//' \
    /workspace/Choochootracker/tracker/platforms/sdl2/corelib_audio.cpp

RUN sed -i \
    -e 's|^int audioOutputDeviceCount.*$|int audioOutputDeviceCount(void) { return 0; }|' \
    -e 's|^  SDL_strlcpy(selectedOutputName.*$|  selectedOutputName[0] = 0;|' \
    /workspace/Choochootracker/tracker/platforms/sdl2/corelib_audio.cpp \
    && grep -Fqx 'int audioOutputDeviceCount(void) { return 0; }' \
        /workspace/Choochootracker/tracker/platforms/sdl2/corelib_audio.cpp \
    && grep -Fqx '  selectedOutputName[0] = 0;' \
        /workspace/Choochootracker/tracker/platforms/sdl2/corelib_audio.cpp

RUN sed -i \
    '/audioOutputSelect(appSettings.audioOutputDeviceName);/i\  appSettings.audioOutputDeviceName[0] = 0;' \
    /workspace/Choochootracker/tracker/src/app.cpp \
    && grep -Fqx '  appSettings.audioOutputDeviceName[0] = 0;' \
        /workspace/Choochootracker/tracker/src/app.cpp

# Record the app's exit status in log.txt so a silent crash is diagnosable.
RUN sed -i 's/\r$//' /workspace/Choochootracker/tracker/packaging/portmaster/ChooChooTracker.sh \
    && sed -i 's|^"\./choochootracker\.\${DEVICE_ARCH}"$|"./choochootracker.${DEVICE_ARCH}"; echo "ChooChooTracker exit status: $?"|' \
        /workspace/Choochootracker/tracker/packaging/portmaster/ChooChooTracker.sh \
    && grep -Fq 'ChooChooTracker exit status' \
        /workspace/Choochootracker/tracker/packaging/portmaster/ChooChooTracker.sh

# LTO of the whole tracker exhausts Docker's memory; other upstream platforms skip it too.
RUN sed -i 's/ -flto / /' /workspace/Choochootracker/tracker/Makefile.common \
    && ! grep -q -- '-flto' /workspace/Choochootracker/tracker/Makefile.common

RUN cd /workspace/Choochootracker/tracker \
    && make -j4 -f Makefile.portmaster PortMaster-deploy \
    && mkdir -p /output \
    && cp ../releases/choochootracker.zip /output/

FROM scratch

COPY --from=build /output/ /
