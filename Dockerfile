# syntax=docker/dockerfile:1.7

# Each GitHub Actions runner builds the CLI natively for its target architecture.
# The official Rust workspace is checked out at an upstream release tag and
# copied into the Docker build context by the publishing workflow.
FROM rust:1.97-bookworm AS builder

WORKDIR /src
COPY upstream/ ./

# BuildKit caches the registry and Git dependencies across repeat builds.
# Cargo.lock determines the Rust dependency revisions; no upstream sources
# are modified by this independent packaging project.
RUN --mount=type=cache,target=/usr/local/cargo/registry,sharing=locked \
    --mount=type=cache,target=/usr/local/cargo/git,sharing=locked \
    cargo build --release --locked --package craft-anything-cli \
    && install -D -m 0755 \
        target/release/craft-anything-cli \
        /out/bin/craft-anything-cli \
    && mkdir -p /out/legal \
    && for file in LICENSE-MIT LICENSE-APACHE NOTICE ATTRIBUTION.md; do \
         if [ -f "$file" ]; then cp "$file" /out/legal/; fi; \
       done

FROM debian:bookworm-slim AS runtime

ARG UPSTREAM_VERSION=unknown
ARG UPSTREAM_SHA=unknown

LABEL org.opencontainers.image.title="Craft Anything Engine" \
      org.opencontainers.image.description="Community-maintained native Craft Anything CLI and stdio MCP server" \
      org.opencontainers.image.source="https://github.com/storytold/craft-anything" \
      org.opencontainers.image.url="https://github.com/MikaPST/craft-anything-engine" \
      org.opencontainers.image.version="${UPSTREAM_VERSION}" \
      org.opencontainers.image.revision="${UPSTREAM_SHA}" \
      org.opencontainers.image.licenses="MIT OR Apache-2.0"

ENV HOME=/data \
    XDG_CONFIG_HOME=/data/config \
    XDG_DATA_HOME=/data/share \
    XDG_CACHE_HOME=/data/cache \
    CRAFT_ANYTHING_LOG=warn \
    PATH=/usr/local/bin:$PATH

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        libgcc-s1 \
        libstdc++6 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 10001 craft \
    && useradd --uid 10001 --gid craft --home-dir /data \
        --create-home --shell /usr/sbin/nologin craft \
    && mkdir -p /data/config /data/share /data/cache /projects /workspace \
    && chown -R craft:craft /data /projects /workspace

COPY --from=builder --chown=craft:craft \
    /out/bin/craft-anything-cli /usr/local/bin/craft-anything-cli
COPY --from=builder /out/legal/ /usr/share/doc/craft-anything/

WORKDIR /workspace
USER 10001:10001

# CLI/MCP over standard streams, not an HTTP daemon. No EXPOSE or HEALTHCHECK.
ENTRYPOINT ["/usr/local/bin/craft-anything-cli"]
CMD ["--help"]
