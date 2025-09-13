FROM oven/bun:latest AS builder

# 通过传入 --build-arg SKIP_WEB_BUILD=true 可以跳过容器内前端构建，
# 使用宿主机预先构建好的 web/dist（可缓解内存不足问题）。
ARG SKIP_WEB_BUILD=false

WORKDIR /build
COPY web/package.json .
COPY web/bun.lock .
RUN bun install
COPY ./web .
COPY ./VERSION .
# 如果不跳过，则正常构建；如果跳过，创建空 dist 目录避免后续 COPY 失败。
RUN if [ "$SKIP_WEB_BUILD" != "true" ]; then \
            echo "[builder] Running bun vite build inside container" && \
            DISABLE_ESLINT_PLUGIN='true' VITE_REACT_APP_VERSION=$(cat VERSION) bun run build ; \
        else \
            echo "[builder] Skipping web build inside container (SKIP_WEB_BUILD=true). Expecting prebuilt web/dist from context" && \
            mkdir -p dist ; \
        fi

FROM golang:alpine AS builder2

ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux

WORKDIR /build

ADD go.mod go.sum ./
RUN go mod download

COPY . .
COPY --from=builder /build/dist ./web/dist
RUN go build -ldflags "-s -w -X 'one-api/common.Version=$(cat VERSION)'" -o one-api

FROM alpine

RUN apk upgrade --no-cache \
    && apk add --no-cache ca-certificates tzdata ffmpeg \
    && update-ca-certificates

COPY --from=builder2 /build/one-api /
EXPOSE 3000
WORKDIR /data
ENTRYPOINT ["/one-api"]
