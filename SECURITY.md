# Security policy

## Scope

This repository packages the upstream Craft Anything CLI and its **stdio** MCP
server. It does not expose a network API or supply a browser frontend. The
container operates as an unprivileged user (UID/GID `10001`) without requiring
privileged mode, Docker socket access or host networking.

The CLI can inspect project files and, depending on explicit options and tool
approvals, may run code or access external services. Its capabilities and
permissions depend on the upstream version and the MCP client configuration.

## Recommended deployment

- Prefer the `mcp --restricted` mode for integrations, particularly shared hosts.
- Do **not** pass `--allow-run` unless the caller and input files are trusted.
- Do **not** mount `/var/run/docker.sock`, host credentials, SSH keys or broad
  host directories unless the use case genuinely requires them.
- Mount targets **read-only** when only inspection is needed. Give write access
  to a dedicated project directory rather than the entire host filesystem.
- Use `--network none` for offline inspection and offline MCP clients. Allow
  network access deliberately when required for explicitly approved backends.
- Keep the Docker daemon and Docker client on trusted machines. An MCP client
  that can invoke Docker can exercise any Docker permissions it has been given.
- Pin a versioned image or manifest digest for predictable deployments. The
  `latest` tag is mutable, and a forced rebuild may refresh versioned tags.
- Be careful with logs, reports and investigations: they may contain sensitive
  content taken from the inspected files or user-supplied settings.

## Reporting vulnerabilities

For vulnerabilities in this Docker packaging, prefer GitHub private security
reporting for this repository when enabled, or contact the maintainer privately.
Do not publish proof-of-concept exploit details in a public issue before a fix.

For vulnerabilities in the Craft Anything CLI or analysis engine, report them to
[the upstream project](https://github.com/storytold/craft-anything/security).

## Updates

GitHub Actions tracks published upstream releases. Images are built from the
selected official source tag with its `Cargo.lock`. The workflow checks both
supported architectures before attaching a matching GitHub Release to the image.
A successful pipeline is not a substitute for a security audit of the upstream
code or its dependencies.
