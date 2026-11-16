<p align="center">
  <img src="https://raw.githubusercontent.com/storytold/craft-anything/main/assets/app-icon/hicolor/256x256/apps/ai.storyteller.craft-anything.png" width="128" height="128" alt="Craft Anything application icon">
</p>

<h1 align="center">Craft Anything Engine — Docker Image</h1>
<p align="center">
  A community-maintained, multi-platform Docker image for the official
  <a href="https://github.com/storytold/craft-anything">Craft Anything</a>
  Rust command-line application and <b>stdio MCP server</b>.
  <br>
  Native Linux builds, automated upstream release tracking and publication to GitHub Container Registry (GHCR).
</p>

<p align="center">
  <a href="https://github.com/MikaPST/craft-anything-engine/actions/workflows/publish-image.yml">
    <img src="https://github.com/MikaPST/craft-anything-engine/actions/workflows/publish-image.yml/badge.svg" alt="Build and publish Craft Anything Engine">
  </a>
  <a href="https://github.com/MikaPST/craft-anything-engine/releases/latest">
    <img src="https://img.shields.io/github/v/release/MikaPST/craft-anything-engine?label=Release&logo=github&color=blue" alt="Latest Release">
  </a>
  <a href="https://github.com/MikaPST/craft-anything-engine/pkgs/container/craft-anything-engine">
    <img src="https://ghcr-badge.egpl.dev/mikapst/craft-anything-engine/latest_tag?trim=major&label=GHCR" alt="GHCR image tag">
  </a>
  <a href="docker-compose.yml">
    <img src="https://img.shields.io/badge/Docker%20Compose-ready-2496ED?logo=docker&logoColor=white" alt="Docker Compose configuration">
  </a>
</p>

---

## Why this repository?

Craft Anything is an open-source project for understanding how software works and crafting new implementations. Its upstream repository includes desktop and browser applications, a Rust CLI, engine crates, MCP integration and other tooling. This repository packages **only the native CLI and its stdio MCP server** into an independently maintained Docker image.

The goals are to:

- Build the official `craft-anything-cli` from a **published upstream release tag**, not a moving `main` checkout.
- Use the corresponding upstream `Cargo.lock` with `cargo build --locked`.
- Publish native `linux/amd64` and `linux/arm64` container images to GHCR.
- Build on separate **native AMD64 and ARM64 GitHub runners**, rather than compiling large Rust dependencies under QEMU.
- Run actual CLI smoke tests on both architectures before publishing the final multi-platform tag.
- Automatically detect new official releases, and create matching GitHub Releases with the source revision and image digest.
- Provide usable Docker Compose and MCP-client examples, including safe filesystem and network defaults.
- Preserve upstream license and attribution notices in the runtime image.
- Keep the container build and distribution configuration independent of the upstream project.

This repository is a packaging and distribution project, not a fork of the Craft Anything engine. It is also a foundation for a **possible future Full Stack deployment**, not that deployment itself.

## How it works

Craft Anything Engine runs as an ordinary Linux command-line process inside a Debian container. There is **no NGINX, WebAssembly web frontend, graphical desktop or network listener** in this image.

- **Native Rust executable:** `craft-anything-cli`, compiled from the official upstream source.
- **CLI tools:** use `commands`, `capabilities`, `triage`, `report`, `doctor`, and other commands supported by the selected upstream release.
- **MCP integration:** `craft-anything-cli mcp` exchanges protocol messages over stdin and stdout.
- **Local projects:** project state and evidence can be persisted with a writable data volume, using upstream CLI project options.
- **Controlled host access:** files become accessible only through explicitly supplied Docker bind mounts.
- **No bundled external engines:** tools such as Ghidra or additional AI runtimes are not installed by this image.

The CLI supports permission-related options, including `mcp --restricted` and the top-level `--allow-run` option. For shared or untrusted MCP integrations, start in restricted mode; grant any more powerful access deliberately.

> [!IMPORTANT]
> This is a **CLI/MCP process, not a server daemon**. Do not deploy it using `docker compose up -d`, configure an HTTP WebUI, or publish a container port. Start a new container for each CLI invocation or let your MCP client start one as a stdio subprocess.

## Docker image

The image is published to GitHub Container Registry:

```text
ghcr.io/mikapst/craft-anything-engine:latest
```

Each successfully packaged upstream release also receives an exact version tag, for example:

```text
ghcr.io/mikapst/craft-anything-engine:v0.6.1
```

The `latest` tag always tracks the latest **official stable release** selected by the workflow. Manually packaging an older upstream tag does not move `latest` backward. A manifest digest is the safest choice when exact image identity is required.

### Option 1 — Docker Compose (recommended for CLI usage)

A `docker-compose.yml` file is provided at the root of this repository. It defines a **profiled, on-demand CLI service**, not a background process:

```yaml
services:
  craft-anything-engine:
    image: ghcr.io/mikapst/craft-anything-engine:latest
    profiles:
      - cli
    init: true
    stdin_open: true
    tty: false
    user: "10001:10001"
    working_dir: /workspace
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    volumes:
      - craft-anything-data:/data
    command:
      - --help

volumes:
  craft-anything-data:
```

From the repository root, invoke a **one-shot command**:

```bash
docker compose run --rm craft-anything-engine --help

docker compose run --rm craft-anything-engine commands

docker compose run --rm craft-anything-engine capabilities

docker compose run --rm craft-anything-engine doctor
```

The `doctor` command reports which upstream capabilities and integrations it can detect. An incomplete report is expected when optional external engines, agents or system integrations are not installed inside the container.

#### Useful Compose commands

```bash
# Update the image used by the CLI service
docker compose pull craft-anything-engine

# Run the MCP server through stdio (interactive input, no pseudo-TTY)
docker compose run --rm -T craft-anything-engine mcp --restricted

# Remove stopped Compose containers without deleting the named volume
docker compose down
```

The `cli` profile prevents the service from starting accidentally with a generic `docker compose up`. The persistent `craft-anything-data` volume stores data under `/data`. No HTTP port, long-running worker, health endpoint or Docker daemon socket is required.

### Option 2 — Run directly with Docker

Run a standalone command:

```bash
docker pull ghcr.io/mikapst/craft-anything-engine:latest

docker run --rm \
  --network none \
  --cap-drop ALL \
  --security-opt no-new-privileges:true \
  ghcr.io/mikapst/craft-anything-engine:latest \
  --help
```

Run an offline inspection against a directory of files without giving the container write access to the originals:

```bash
mkdir -p "$PWD/targets"

docker run --rm \
  --network none \
  --mount type=volume,src=craft-anything-data,dst=/data \
  --mount "type=bind,src=$PWD/targets,dst=/projects,readonly" \
  ghcr.io/mikapst/craft-anything-engine:latest \
  --project /data/projects/research.cany \
  triage /projects/example.bin
```

Replace `example.bin` with a real file under the host's `targets/` directory. The source files are read-only; investigation state is kept in the named Docker volume. The CLI runs as UID/GID `10001`, so any writable host bind mount must allow that user to write.

### MCP over standard input/output

The official MCP command is:

```bash
craft-anything-cli mcp
```

Docker-based MCP clients must launch the image with **`-i` and without `-t`**. Example client configuration (adapt the absolute host directory to your machine):

```json
{
  "mcpServers": {
    "craft-anything": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i", "--network", "none",
        "--cap-drop", "ALL",
        "--security-opt", "no-new-privileges:true",
        "--mount", "type=volume,src=craft-anything-data,dst=/data",
        "--mount", "type=bind,src=/absolute/path/to/targets,dst=/projects,readonly",
        "ghcr.io/mikapst/craft-anything-engine:latest",
        "mcp", "--restricted"
      ]
    }
  }
}
```

The Docker executable must be accessible to the MCP client, and the target directory must already exist. The exact MCP configuration keys depend on the client's implementation; the example shows the common `mcpServers` convention.

`--network none` is suitable for **offline** analysis. Remove it only when the selected CLI features or approved AI backends genuinely need network access. In restricted mode, web and capture tools are disabled by default; refer to the upstream CLI help for any deliberate exceptions.

### Persistent data and permissions

The container runs as the unprivileged user `craft` (UID/GID `10001`) and defines the following paths:

| Container path | Purpose |
|---|---|
| `/data/config` | Configuration (`XDG_CONFIG_HOME`) |
| `/data/share` | Application data (`XDG_DATA_HOME`) |
| `/data/cache` | Cache (`XDG_CACHE_HOME`) |
| `/data/projects` | Example location for persistent `.cany` project folders |
| `/projects` | Conventional mount point for external targets |
| `/workspace` | Default working directory |

The paths above are container conventions. They are **not additional upstream CLI flags**. The configured volume is writable; host bind mounts can be restricted to read-only when appropriate.

Do not mount your entire home directory, cloud credentials or `/var/run/docker.sock` into an MCP container merely for convenience. Avoid granting `--allow-run` to untrusted clients. See [SECURITY.md](SECURITY.md) for the recommended precautions.

## Repository structure

The Docker packaging is version-controlled independently of the official Craft Anything source.

```text
craft-anything-engine/
├── .github/
│   ├── dependabot.yml
│   └── workflows/
│       └── publish-image.yml
├── .dockerignore
├── Dockerfile
├── docker-compose.yml
├── README.md
└── SECURITY.md
```

| File | Purpose |
|---|---|
| `Dockerfile` | Builds the official Rust CLI and packages it into a non-root Debian runtime, preserving legal notices |
| `.dockerignore` | Keeps Git metadata, build output and other unnecessary files out of the Docker context |
| `docker-compose.yml` | Defines a safe, on-demand CLI/MCP service and persistent data volume |
| `.github/workflows/publish-image.yml` | Resolves releases, builds native AMD64/ARM64 images, tests them, merges the multi-platform manifest and creates GitHub Releases |
| `.github/dependabot.yml` | Tracks GitHub Actions and Docker base-image updates |
| `SECURITY.md` | Documents scope, permissions, mount safety and vulnerability reporting |
| `README.md` | Explains CLI, Compose, MCP, image publication and the Full Stack boundary |

### Docker build architecture

Unlike the other ArtCraft Web projects, this image does not build WebAssembly or run NGINX. It compiles a **native Linux Rust executable for each architecture**.

The GitHub Actions workflow follows these steps:

1. Identify the latest published upstream release or a specific tag requested manually.
2. Check whether the corresponding version already has a GitHub Release in this packaging repository.
3. Checkout the exact upstream tag, confirm its CLI package and `Cargo.lock`, and record its full commit SHA.
4. Run two native build jobs: `ubuntu-24.04` for `linux/amd64`, and `ubuntu-24.04-arm` for `linux/arm64`.
5. Compile `craft-anything-cli` from source with Rust 1.97 and `cargo build --release --locked --package craft-anything-cli`.
6. Package the binary, essential runtime libraries and the upstream license and attribution notices in a non-root Debian image.
7. Push each architecture's image by its **immutable digest** and smoke-test its CLI commands on the corresponding native runner.
8. Download both verified image digests and assemble one multi-platform manifest under the versioned and source-commit tags.
9. Publish `latest` only if the selected version is the latest official stable release; verify both architectures in the resulting manifest.
10. Create or update the matching GitHub Release **only after** the multi-platform image is published and verified.

Each runner uses Docker Buildx caching scoped to its own architecture. GitHub Actions additionally attaches build provenance and an SBOM to the published images. Build steps preserve upstream source files and lockfile contents, rather than modifying the Craft Anything project.

The image contains only the CLI binary, the small Debian runtime requirements and legal notices. It runs as UID/GID `10001` and does not expose an HTTP port or require privileged execution.

> [!NOTE]
> Rust, Ubuntu runners and upstream dependencies may change. Architecture compatibility must be confirmed in a real GitHub Actions run; static validation alone cannot prove the full Rust build will succeed.

## Automated builds

GitHub Actions checks the official upstream release feed and packages newly published stable versions.

| Trigger | Behaviour |
|---|---|
| Daily schedule | Checks the latest official Craft Anything release and skips versions already packaged |
| Manual workflow dispatch | Packages the latest official release or a specific published upstream tag |
| Force rebuild | Rebuilds an already packaged upstream version when `force_rebuild` is enabled |
| Packaging changes on `main` | Rebuilds the latest official release when Docker, Compose or the publishing workflow changes |

Documentation-only changes do **not** start an expensive native multi-platform Rust compilation. The workflow uses a concurrency guard so publishing runs cannot overwrite each other's tags simultaneously.

### Published tags

A successful build publishes these image tags:

- `latest` — the latest successfully packaged **stable upstream release**; not updated when manually packaging an older or prerelease tag.
- `<upstream-version>` — the exact official upstream release tag, such as `v0.6.1`.
- `upstream-<commit>` — the first 12 characters of the official source commit used for the image.

The workflow checks the selected release's source revision before compiling and verifies that the final manifest contains both `linux/amd64` and `linux/arm64`.

### GitHub Releases

Following successful container publication and smoke tests, the workflow creates or updates a matching [GitHub Release](https://github.com/MikaPST/craft-anything-engine/releases).

Each release includes:

- The official upstream release name, URL and release notes.
- The exact upstream tag and full source commit.
- Published Docker tags and the final multi-platform image digest.
- Supported architectures: `linux/amd64` and `linux/arm64`.
- An explicit notice that this is **independent community packaging**, not an official upstream binary distribution.

The four badges at the top of this README indicate GitHub Actions status, the latest published release, the GHCR image version and Docker Compose availability. The Release badge may initially show no version **until the first image has been successfully published**.

To rebuild an existing version, use **Actions → Build and publish Craft Anything Engine → Run workflow**, set the upstream tag as needed and enable `force_rebuild`.

> [!IMPORTANT]
> `latest` is mutable. Forced rebuilds can also update an existing versioned image tag. For exact, auditable deployment use the published `sha256:` manifest digest.

## Unraid Community Applications

This image is suitable for manual Docker or Docker Compose use on Unraid. However, it is a **command-line/MCP image**, not a WebUI application, and should not be configured as a permanently running web container.

An official Unraid Community Applications XML template for `craft-anything-engine` is **not included in this repository**. The Docker Compose example is the supported starting point for on-demand execution. A dedicated Unraid template can be added separately after the command-line use case and any required integration with a future Full Stack deployment have been validated.

## Upstream project

**Craft Anything** is an open-source Rust application for software investigation and reimplementation. The upstream repository provides several components; this image packages only its headless CLI and MCP features.

- **Source code:** [storytold/craft-anything](https://github.com/storytold/craft-anything)
- **Official website:** [getartcraft.com](https://getartcraft.com/)
- **Official releases:** [Craft Anything GitHub Releases](https://github.com/storytold/craft-anything/releases)
- **CLI package:** [apps/craft-anything-cli](https://github.com/storytold/craft-anything/tree/main/apps/craft-anything-cli)
- **Upstream security policy:** [SECURITY.md](https://github.com/storytold/craft-anything/blob/main/SECURITY.md)

### Future Full Stack deployment

A full browser-based deployment would be a **different project** requiring a packaged web frontend, an authenticated API/backend, a task queue or session manager, deliberate per-user filesystem and credential isolation, and any selected optional analysis engines. The CLI image does **not** silently provide these services or expose MCP over HTTP.

## License and attribution

Craft Anything is dual-licensed under **MIT OR Apache-2.0**, at the user's option. The official authors and contributors retain their rights to the upstream application, logos, bundled resources and other assets.

- [MIT license](https://github.com/storytold/craft-anything/blob/main/LICENSE-MIT)
- [Apache 2.0 license](https://github.com/storytold/craft-anything/blob/main/LICENSE-APACHE)
- [Upstream NOTICE](https://github.com/storytold/craft-anything/blob/main/NOTICE)
- [Upstream asset attribution](https://github.com/storytold/craft-anything/blob/main/ATTRIBUTION.md)

The Dockerfile preserves available upstream license and attribution files in `/usr/share/doc/craft-anything/` within the runtime image. Those terms apply to the upstream application; they do not automatically determine the license of the independently maintained packaging files. No separate packaging license is asserted unless one is explicitly added to this repository.

The Craft Anything and ArtCraft names, marks and logos remain the property of their respective owners. This image is independently maintained and is **not affiliated with, endorsed by or supported by the upstream maintainers**.

## Disclaimer

Craft Anything and its investigation tools are evolving. Features, commands, formats, agent integrations and security boundaries can change between upstream releases. Test updated images and verify any analysis results before using them in critical work.
