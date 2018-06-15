FROM python:2.7-alpine3.7

# GOLANG install steps used from the official golang:1.7-alpine image
# at https://github.com/docker-library/golang/tree/f19fa68b57e811315e95091bb6b78c1e2f43d14f
RUN apk add --no-cache ca-certificates

ENV GOLANG_VERSION 1.10.3
ENV GOLANG_SRC_URL https://golang.org/dl/go$GOLANG_VERSION.src.tar.gz
ENV GOLANG_SRC_SHA256 567b1cc66c9704d1c019c50bef946272e911ec6baf244310f87f4e678be155f2

# https://golang.org/issue/14851
COPY no-pic.patch /
# https://golang.org/issue/17847
COPY 17847.patch /

RUN apk add --no-cache --virtual .build-deps \
		bash \
		gcc \
		musl-dev \
		openssl \
		go && \
	export GOROOT_BOOTSTRAP="$(go env GOROOT)" && \
	wget -q "$GOLANG_SRC_URL" -O golang.tar.gz && \
	echo "$GOLANG_SRC_SHA256  golang.tar.gz" | sha256sum -c - && \
	tar -C /usr/local -xzf golang.tar.gz && \
	rm golang.tar.gz && \
	cd /usr/local/go/src && \
//	patch -p2 -i /no-pic.patch && \
//	patch -p2 -i /17847.patch && \
	./make.bash && \
	rm -rf /*.patch && \
	apk del .build-deps

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
WORKDIR $GOPATH

# Controller install steps
COPY entrypoint.builder.sh /entrypoint.sh
COPY requirements.txt /tmp/requirements.txt
COPY requirements.docs.txt /tmp/requirements.docs.txt

RUN apk add --no-cache \
		bash \
		gcc \
		git \
		make \
		musl-dev \
		rsync \
		su-exec && \
	pip install setuptools flake8 && \
	pip install --process-dependency-links -r /tmp/requirements.txt && \
	pip install -r /tmp/requirements.docs.txt && \
        pip install virtualenv && \
	go get github.com/wadey/gocovmerge && \
        go get github.com/nats-io/gnatsd && \
        go get github.com/onsi/ginkgo/ginkgo && \
        go get github.com/onsi/gomega && \
        go get github.com/mattn/goveralls && \
	chmod 755 /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/bin/bash" ]
