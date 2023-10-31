# syntax=docker/dockerfile:experimental
# NOTE next 3 items are taken from here
# https://github.com/ZuBB/base-2204-python38/tree/size-reduce
# and hopefully they will be upstreamed
# https://github.com/canonical/base-2204-python38/issues/3
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true \
    PYTHONUNBUFFERED=1

RUN apt update && \
    apt upgrade -y && \
    apt install -y gnupg && \
    gpg --list-keys && \
    gpg --no-default-keyring --keyring /usr/share/keyrings/deadsnakes.gpg --keyserver keyserver.ubuntu.com --recv-keys F23C5A6CF475977595C89F51BA6932366A755776 && \
    echo 'deb [signed-by=/usr/share/keyrings/deadsnakes.gpg] http://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy main' | tee -a /etc/apt/sources.list.d/python.list && \
    apt update && \
    apt install curl python3.8 python3.8-distutils -y && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.8 1 && \
    curl -o - https://bootstrap.pypa.io/get-pip.py | python - && \
    apt purge -y gnupg curl && \
    apt autoremove --purge -y && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /root/.cache/pip && \
    apt clean


ARG DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true \
    PYTHONUNBUFFERED=1

# Install* and Cleanup
#  * required packages
#  * Ace Stream (https://docs.acestream.net/products/#linux)
#  * Ace Stream's dependencies
RUN apt-get update -yq && \
    apt-get upgrade -yq && \
    apt-get install -yq --no-install-recommends python3.8-dev build-essential curl && \
    mkdir -p /opt/acestream && \
    curl -so - "https://download.acestream.media/linux/acestream_3.1.75rc4_ubuntu_18.04_x86_64_py3.8.tar.gz" | tar --extract --gzip --directory /opt/acestream --file - && \
    pip install -qr /opt/acestream/requirements.txt && \
    apt-get purge build-essential curl -yq && \
    apt autoremove --purge -y && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /root/.cache/pip && \
    apt clean && \
    /opt/acestream/start-engine --version

# Overwrite disfunctional Ace Stream web player with a working videojs player,
# Access at http://127.0.0.1:6878/webui/player/<acestream id>
# TODO its an overwite. do we still need it?
COPY player.html /opt/acestream/data/webui/html/player.html

# Prep dir
# NOTE seems useless
RUN mkdir /acelink

# TODO its an overwite. do we still need it?
COPY acestream.conf /opt/acestream/acestream.conf
ENTRYPOINT ["/opt/acestream/start-engine", "@/opt/acestream/acestream.conf"]

HEALTHCHECK CMD wget -q -t1 -O- 'http://127.0.0.1:6878/webui/api/service?method=get_version' | grep '"error": null'

EXPOSE 6878
EXPOSE 8621
