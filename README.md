# Craft Anything Engine — Docker Image

A community-maintained multi-architecture Docker image for the official [Craft Anything](https://github.com/storytold/craft-anything) command-line application.

This image compiles the upstream Rust CLI from source and packages the resulting native executable in a minimal Debian runtime image. It is the backend foundation for a planned Craft Anything Full Stack deployment on Unraid.

## Included

- Official `craft-anything-cli` binary.
- Official Rust analysis engine and registered CLI tools.
- Official MCP server over standard input/output (`stdio`).
- Native Linux images for `linux/amd64` and `linux/arm64`.

The image does not include the desktop GUI, browser viewer, a custom HTTP API, coding agents or external analysis engines such as Ghidra.

## Image

```text
ghcr.io/mikapst/craft-anything-engine:latest
```

## Quick start

```bash
docker pull ghcr.io/mikapst/craft-anything-engine:latest

docker run --rm \
  ghcr.io/mikapst/craft-anything-engine:latest \
  --help
```

List the commands available in the upstream CLI:

```bash
docker run --rm \
  ghcr.io/mikapst/craft-anything-engine:latest \
  commands
```

Check the CLI's installation and detected tools:

```bash
docker run --rm \
  ghcr.io/mikapst/craft-anything-engine:latest \
  doctor
```

## Persistent paths

The image runs as the unprivileged `craft` user (UID/GID `10001`) and uses these paths:

| Container path | Purpose |
|---|---|
| `/data/config` | Application configuration |
| `/data/share` | Application data |
| `/data/cache` | Cache |
| `/projects` | Project folders |
| `/workspace` | Current working directory |

Mount host directories at these locations and ensure they are writable by UID/GID `10001`.

The upstream CLI uses its own configuration and project conventions. The paths above are container defaults, not new upstream CLI flags.

## MCP

The upstream CLI exposes its MCP server through stdio:

```bash
craft-anything-cli mcp
```

For Docker-based MCP clients, use the container as a stdio process with an interactive stdin connection. This image does not expose an MCP TCP/HTTP port. Network-accessible MCP will be addressed separately after a supported transport or a properly secured adapter has been implemented and tested.

## Build and release

GitHub Actions:

- Builds the official CLI from the upstream `main` branch.
- Uses the upstream `Cargo.lock` with `--locked`.
- Runs CLI help smoke tests on the GitHub runner.
- Builds and publishes `linux/amd64` and `linux/arm64` images.
- Publishes `latest` and `upstream-<commit>` tags.
- Runs weekly and can be triggered manually.

The GitHub Actions workflow has not yet been executed in this repository. Multi-architecture builds and runtime compatibility must be validated on the first real workflow run.

## Current scope and next steps

This is the native CLI/MCP engine image only. The planned Full Stack deployment still requires:

1. A separately packaged web frontend.
2. A custom backend API and task manager to connect the browser interface to the engine.
3. Optional agent runtimes and their credential/configuration handling.
4. Optional external analysis engines such as Ghidra.
5. A secured network MCP transport if remote MCP clients need direct access.

## Upstream

- Source: https://github.com/storytold/craft-anything
- CLI package: `apps/craft-anything-cli`
- MCP command: `craft-anything-cli mcp`
- License: see the upstream repository's MIT and Apache-2.0 license files.

This is an independent community packaging project and is not affiliated with or endorsed by the upstream maintainers.
