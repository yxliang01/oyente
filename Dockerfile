ARG ETHEREUM_VERSION=alltools-v1.7.3
ARG SOLC_VERSION=0.4.19

FROM ethereum/client-go:${ETHEREUM_VERSION} as geth
FROM ethereum/solc:${SOLC_VERSION} as solc

FROM ubuntu:bionic

ARG NODEREPO=node_8.x

LABEL maintainer "Luong Nguyen <luongnt.58@gmail.com>"

SHELL ["/bin/bash", "-c", "-l"]
RUN apt-get update && apt-get -y upgrade
RUN apt-get install -y wget unzip python-virtualenv git build-essential software-properties-common curl
RUN curl -s 'https://deb.nodesource.com/gpgkey/nodesource.gpg.key' | apt-key add -
RUN apt-add-repository "deb https://deb.nodesource.com/${NODEREPO} $(lsb_release -c -s) main"
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update
RUN apt-get install -y musl-dev golang-go python3 python3-pip python-pip \
        bison zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libreadline-dev \
	zlib1g-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 \
        libxml2-dev libxslt1-dev libcurl4-openssl-dev libffi-dev nodejs yarn && \
        apt-get clean

RUN update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.6 2
RUN update-alternatives --install /usr/bin/pip pip /usr/bin/pip2 1
RUN update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 2
RUN pip install requests web3
RUN npm install npm@latest -g  && npm install n --global && n stable

RUN mkdir -p /deps/z3/ &&  wget https://github.com/Z3Prover/z3/archive/z3-4.8.6.zip -O /deps/z3/z3.zip && \
        cd /deps/z3/ && unzip /deps/z3/z3.zip && \
        ls /deps/z3 && mv /deps/z3/z3-z3-4.8.6/* /deps/z3/ &&  rm /deps/z3/z3.zip && \
        python scripts/mk_make.py --python && cd build && make -j$(nproc) && make install

# Instsall geth from official geth image
COPY --from=geth /usr/local/bin/evm /usr/local/bin/evm

# Install solc from official solc image
COPY --from=solc /usr/bin/solc /usr/bin/solc

COPY . /oyente/

RUN useradd -m oyente
USER oyente

CMD "/bin/bash"
