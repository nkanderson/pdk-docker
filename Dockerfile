FROM ubuntu:bionic

WORKDIR /root

ADD install-pdk-release.sh .
ADD install-onceover.sh .
ADD pdk-release.env .

RUN apt-get update && \
    apt-get install -y curl openssh-client && \
    ./install-pdk-release.sh && \
    ./install-onceover.sh && \
    apt-get purge -y curl && \
    apt-get autoremove -y && \
    groupadd -g 999 pdk && \
    useradd -mr -u 999 -g pdk pdk && \
    rm -rf /var/lib/apt/lists/*

ENV PATH="${PATH}:/opt/puppetlabs/pdk/private/git/bin"
ENV PDK_DISABLE_ANALYTICS=true

USER pdk

WORKDIR /home/pdk

ENTRYPOINT ["/opt/puppetlabs/pdk/bin/pdk"]
