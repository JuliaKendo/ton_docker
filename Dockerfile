FROM node:22-alpine AS nodes
WORKDIR /app
COPY package.json ./
RUN npm install

FROM ubuntu:22.04 AS base-deps
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y openssl wget curl git && \
    rm -rf /var/lib/apt/lists/*

FROM base-deps AS builder
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential cmake clang libssl-dev pkg-config libsecp256k1-dev libsodium-dev libmicrohttpd-dev zlib1g-dev liblz4-dev gperf autoconf libtool && \
	rm -rf /var/lib/apt/lists/*
ENV CC=clang
ENV CXX=clang++

ARG TON_GIT=https://github.com/ton-blockchain/ton
ARG TON_BRANCH=testnet
ARG BUILD_DEBUG=0

WORKDIR /

RUN echo "Cloning ${TON_GIT} ${TON_BRANCH}" && \
	git clone -b ${TON_BRANCH} --recursive ${TON_GIT} && \
    	git clone https://github.com/disintar/toncli

WORKDIR /ton

RUN mkdir build && \
	cd build && \
	if [ ${BUILD_DEBUG} -eq 0 ]; then \
		cmake .. -DTON_ARCH="" -DPORTABLE=1 -DCMAKE_BUILD_TYPE=Release; \
	else \
		cmake .. -DTON_ARCH="" -DPORTABLE=1; \
	fi && \
	cmake --build . --parallel $(nproc) -j $(nproc) --target fift && \
	cmake --build . --parallel  $(nproc) -j $(nproc)  --target func && \
	cmake --build . --parallel  $(nproc) -j $(nproc)  --target lite-client && \
	cmake --build . --parallel  $(nproc) -j $(nproc)  --target tonlibjson

FROM base-deps
RUN apt-get update && \
	apt-get install -y curl && \
	curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y libsodium23 libsecp256k1-0 python3 pip nodejs && \
	rm -rf /var/lib/apt/lists/*

COPY --from=builder /ton/build/lite-client/lite-client /usr/local/bin/
COPY --from=builder /ton/build/crypto/func /usr/local/bin/
COPY --from=builder /ton/build/crypto/fift /usr/local/bin/
COPY --from=builder /ton/build/tonlib/libtonlibjson.so /usr/local/lib/
COPY --from=builder /toncli /toncli
COPY --from=nodes /app/node_modules ./node_modules
COPY --from=nodes /app/package.json ./
COPY --from=nodes /app/package-lock.json ./

WORKDIR /

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 10 && \
	python -m pip install --upgrade pip && \
	pip install -e toncli

ENV TONCLI_CONFD=.config/toncli/
ENV TONCLI_CONF_NAME=config.ini

RUN mkdir -p $HOME/$TONCLI_CONFD && \
	cp /toncli/src/toncli/$TONCLI_CONF_NAME $HOME/$TONCLI_CONFD/ && \
	echo "\n\n[executable]" >> ${HOME}/${TONCLI_CONFD}/$TONCLI_CONF_NAME && \
	echo "func = /usr/local/bin/func" >> $HOME/$TONCLI_CONFD/$TONCLI_CONF_NAME && \
	echo "fift = /usr/local/bin/fift" >> $HOME/$TONCLI_CONFD/$TONCLI_CONF_NAME&& \
	echo "lite-client = /usr/local/bin/lite-client" >> $HOME/$TONCLI_CONFD/$TONCLI_CONF_NAME && \
	toncli update_libs && \
	mkdir -p /code

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

WORKDIR /code
