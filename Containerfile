# Build stage using specific images from stagex
FROM scratch AS build
COPY --from=stagex/pallet-go@sha256:da4d8eec91b2f34bb5cf4946f64fd46c4d914691435fa83dc6d777993e50de62 . /
COPY --from=stagex/gcc:13.1.0@sha256:439bf36289ef036a934129d69dd6b4c196427e4f8e28bc1a3de5b9aab6e062f0 . /
COPY --from=stagex/binutils:2.43.1@sha256:30a1bd110273894fe91c3a4a2103894f53eaac43cf12a035008a6982cb0e6908 . /
COPY --from=stagex/libunwind:1.7.2@sha256:97ee6068a8e8c9f1c74409f80681069c8051abb31f9559dedf0d0d562d3bfc82 . /
COPY --from=stagex/musl:1.2.4@sha256:ad351b875f26294562d21740a3ee51c23609f15e6f9f0310e0994179c4231e1d . /
COPY --from=stagex/llvm:18.1.8@sha256:30517a41af648305afe6398af5b8c527d25545037df9d977018c657ba1b1708f . /
COPY --from=stagex/zlib:1.3.1@sha256:96b4100550760026065dac57148d99e20a03d17e5ee20d6b32cbacd61125dbb6 . /
COPY --from=stagex/openssl:latest@sha256:8e3eb24b4d21639f7ea204b89211d8bc03a2e1b729fb1123f8d0b3752b4beaa1 . /

# Set system time to 00:00:01 UTC
ENV SOURCE_DATE_EPOCH=1

WORKDIR /app

# Copy Go files and source
COPY go.mod go.sum* /app/
RUN ["go", "mod", "download"]

# Copy source code
COPY main.go /app/
COPY . /app/

# Build the Go application with static linking
RUN --network=none CGO_ENABLED=0 GOOS=linux go build -a -ldflags='-extldflags "-static" -s -w' -o /hello main.go

# Runtime stage - minimal scratch image
FROM scratch

# Copy SSL certificates for HTTPS requests
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy the compiled binary
COPY --from=build /hello /hello

# Set the entry point
ENTRYPOINT ["/hello"]