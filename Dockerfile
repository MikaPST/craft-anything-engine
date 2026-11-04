# syntax=docker/dockerfile:1

# Build the official Craft Anything CLI for the target platform.
# Buildx runs this stage for each requested platform (QEMU is enabled in CI).
FROM rust:1.97-bookworm AS builder

WORKDIR /src

# The upstream source is copied into the build context by GitHub Actions.
COPY upstream/ ./

# Compile only the headless CLI. The desktop UI is not part of this image.
RUN cargo build \
      --release \
      --locked \
      --package craft-anything-cli \
    && install -D -m 0755 \
      target/release/craft-anything-cli \
      /out/craft-anything-cli

# Runtime image: no Rust toolchain, Cargo or source tree.
FROM debian:bookworm-slim AS runtime

ENV HOME=/data \
    XDG_CONFIG_HOME=/data/config \
    XDG_DATA_HOME=/data/share \
    XDG_CACHE_HOME=/data/cache \
    CRAFT_ANYTHING_LOG=info \
    PATH=/usr/local/bin:$PATH

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      libgcc-s1 \
      libstdc++6 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 10001 craft \
    && useradd --uid 10001 --gid craft --home-dir /data --create-home \
      --shell /usr/sbin/nologin craft \
    && mkdir -p \
      /data/config \
      /data/share \
      /data/cache \
      /projects \
      /workspace \
    && chown -R craft:craft /data /projects /workspace

COPY --from=builder --chown=craft:craft \
    /out/craft-anything-cli \
    /usr/local/bin/craft-anything-cli

WORKDIR /workspace

USER craft:craft

# MCP uses stdio. No network port is exposed by this CLI-only image.
ENTRYPOINT ["/usr/local/bin/craft-anything-cli"]
CMD ["--help"]
