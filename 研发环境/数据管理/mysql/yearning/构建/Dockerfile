# 构建环境for nodejs
FROM node:12 as node_builder
WORKDIR /Yearning-go/
COPY Yearning-gemini-2.3.2.tar.gz Yearning-gemini-2.3.2.tar.gz
RUN set -ex \
    && npm config set registry https://registry.npm.taobao.org \
    && npm i \
    && npm build
# 构建环境for golang
FROM golang:1.16 as builder
WORKDIR /Yearning-go/
COPY Yearning-2.3.5.tar.gz Yearning-2.3.5.tar.gz
RUN set -ex \
    && tar -zvxf Yearning-2.3.5.tar.gz \
    && cd Yearning-2.3.5/ \
    && go env -w CGO_ENABLED=0 \
    && go env -w GOOS=linux \
    && go env -w GOARCH=amd64 \
    && go env -w CGO_ENABLED=0 \
    && go env -w GO111MODULE=on \
    && go env -w GOPROXY=https://goproxy.cn,direct \
    && go mod download \
    && go get \
    && go build . \
    && chmod +x Yearning-go
# 运行环境
FROM golang:1.16
WORKDIR /Yearning-go/
COPY --from=builder /Yearning-go/Yearning-gemini-2.3.2/dist /Yearning-go/
COPY --from=builder /Yearning-go/Yearning-2.3.5/Yearning-go /Yearning-go/
EXPOSE 8000
ENTRYPOINT  ["./Yearning-go"]
CMD ["-m", "-s"]