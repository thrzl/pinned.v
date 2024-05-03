FROM alpine:latest as install-v
RUN apk add --no-cache git clang make musl-dev
RUN git clone https://github.com/vlang/v /opt/vlang
WORKDIR /opt/vlang
RUN make
RUN ln -s /opt/vlang/v /usr/local/bin/v
WORKDIR /
RUN mkdir -p /usr/app
WORKDIR /usr/app
COPY . .
RUN v install
ENTRYPOINT ["v", "run", ".", "-prod"]
