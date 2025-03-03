# Use a specific digest for the Rust image to ensure reproducibility
FROM rust:1.81.0@sha256:7b7f7ae5e49819e708369d49925360bde2af4f1962842e75a14af17342f08262 AS builder

# Set fixed timestamp for reproducibility
ARG SOURCE_DATE_EPOCH=1609459200

# Set environment variables for reproducible builds
ENV SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH} \
    RUSTFLAGS="-C target-feature=+crt-static" \
    CARGO_BUILD_RUSTFLAGS="-C target-feature=+crt-static" \
    RUSTC_BOOTSTRAP=1

# Create a new empty project
WORKDIR /app
RUN cargo init --bin .

# Copy project manifest and lock files
COPY Cargo.toml /app/

# Copy source files
COPY src/ /app/src/

# First generate the lock file
RUN cargo generate-lockfile

# Build the application with fixed settings for reproducibility
RUN cargo build --release \
    # Configure cargo for reproducible builds
    --config "build.rustc-wrapper=''" \
    --config "build.incremental=false" \
    && \
    # List the target directory to find the binary
    ls -la /app/target/release && \
    # Standardize file timestamps for all generated files
    find /app/target -type f -exec touch --no-dereference --date=@${SOURCE_DATE_EPOCH} {} \;

# Use a minimal base image for the final image
FROM debian:bullseye-slim@sha256:33b7c2e071c29e618182ec872c471f39d2dde3d8904d95f5b7a61acf3a592e7b

# Set fixed timestamp again to ensure consistency
ARG SOURCE_DATE_EPOCH=1609459200
ENV SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH}

# Create a non-root user
RUN groupadd --gid 10001 rust && \
    useradd --uid 10000 --gid rust --shell /sbin/nologin --create-home rust && \
    # Standardize file timestamps
    find /etc -type f -exec touch --no-dereference --date=@${SOURCE_DATE_EPOCH} {} \;

# Copy all binaries from the release directory
COPY --from=builder --chown=rust:rust /app/target/release/ /usr/local/bin/

# List binaries in destination to debug
RUN ls -la /usr/local/bin/ && \
    # Set file timestamps for all binaries
    find /usr/local/bin -type f -exec touch --no-dereference --date=@${SOURCE_DATE_EPOCH} {} \;

# Switch to non-root user
USER rust

# Set the entrypoint - we'll use the actual binary name from the output
ENTRYPOINT ["/usr/local/bin/reproducible-builds"]