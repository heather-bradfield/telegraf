FROM golang:1.21-bookworm as builder

WORKDIR /telegraf

ENV TELEGRAF_VERSION=1.28.0

RUN apt-get update && \
    apt-get install  -y --no-install-recommends ruby ruby-dev rubygems build-essential && \
    gem install fpm

RUN git clone https://github.com/heather-bradfield/telegraf.git .
RUN git checkout tail-fix
RUN make package include_packages="amd64.deb"   

FROM buildpack-deps:bookworm-curl

ENV DEBIAN_FRONTEND=noninteractive

COPY --from=builder /telegraf/build/dist/* /home

RUN apt-get update && \
    apt-get install -y /home/telegraf_*.deb && \
    rm -f /home/telegraf_*.deb

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends iputils-ping snmp procps lm-sensors libcap2-bin

RUN  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends inotify-tools;

RUN rm -rf /var/lib/apt/lists/*

RUN set -ex && \
    mkdir ~/.gnupg; \
    echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf; \
    for key in \
        9D539D90D3328DC7D6C8D3B9D8FF8E1F7DF8B07E ; \
    do \
        gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys "$key" ; \
    done

EXPOSE 8125/udp 8092/udp 8094

COPY ./entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["telegraf"]
