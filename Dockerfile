FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive
# apt packages
ENV INSTALL_DEPS \
  ca-certificates \
  git \
  make \
  zip \
  unzip \
  g++ \
  wget \
  maven \
  patch \
  python3 \
  python3-distutils \
  python3-setuptools \
  apt-transport-https \
  curl \
  openjdk-8-jdk \
  gnupg 

RUN apt update \
  && apt install -y -q --no-install-recommends ${INSTALL_DEPS} \
  && apt clean

# bazel
ENV BAZEL_VER=5.3.0
RUN wget -O bazel https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VER}/bazel-${BAZEL_VER}-linux-$([ $(uname -m) = "aarch64" ] && echo "arm64" || echo "x86_64") \
  && chmod +x bazel \
  && mv bazel usr/local/bin/bazel

# protoc
ENV PROTOC_VER=21.5
RUN export PROTOC_REL=protoc-${PROTOC_VER}-linux-$([ $(uname -m) = "aarch64" ] && echo "aarch" || echo "x86")_64.zip \
  && wget https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VER}/${PROTOC_REL} \
  && unzip ${PROTOC_REL} -d protoc \
  && mv protoc /usr/local \
  && ln -s /usr/local/protoc/bin/protoc /usr/local/bin

# go
ENV GOROOT /usr/local/go
ENV GOPATH /go
ENV PATH $GOPATH/bin:$GOROOT/bin:$PATH
RUN export GORELEASE=go1.18.5.linux-$([ $(uname -m) = "aarch64" ] && echo "arm64" || echo "amd64").tar.gz \
  && wget -q https://dl.google.com/go/$GORELEASE \
  && tar -C $(dirname $GOROOT) -xzf $GORELEASE \
  && rm $GORELEASE \
  && mkdir -p $GOPATH/{src,bin,pkg}

# protoc-gen-go
ENV PGG_VER=v1.27.1
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@${PGG_VER}

# buildozer
ENV BDR_VER=5.1.0
RUN go install github.com/bazelbuild/buildtools/buildozer@${BDR_VER} 

# clean go/mod cache
RUN rm -rf $(go env GOCACHE) \
  && rm -rf $(go env GOMODCACHE)

WORKDIR ${GOPATH}/src/github.com/envoyproxy/protoc-gen-validate
COPY . .

# python must be on PATH for the execution of py_binary bazel targets, but
# the distribution we installed doesn't provide this alias
RUN ln -s /usr/bin/python3.8 /usr/bin/python

# python tooling for linting and uploading to PyPI
RUN python3.8 -m easy_install pip \
  && python3.8 -m pip install -r requirements.txt

RUN make build

ENTRYPOINT ["make"]
CMD ["build"]
