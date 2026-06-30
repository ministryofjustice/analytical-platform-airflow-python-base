---
description: "Use when patching, updating, or bumping apt package versions in the Dockerfile. Covers how to find the latest available version of a package and how to update the pinned version in the apt-get install block."
applyTo: "Dockerfile"
---

# Patching APT Packages

APT packages in the Dockerfile are pinned to exact versions using the format `"package=version"`.

## Finding the Latest Version

Spin up the base Ubuntu image (always with `--platform linux/amd64`) and query `apt-cache policy`:

```bash
docker run -it --rm --platform linux/amd64 public.ecr.aws/ubuntu/ubuntu:24.04

apt-get update

apt-cache policy <package>
```

The `Candidate:` line in the output is the version to use.

## Updating a Package Version

In the `# Base Configuration` `RUN` block, locate the package in the `apt-get install --yes` block and update its pinned version:

```dockerfile
apt-get install --yes \
  "curl=8.5.0-2ubuntu10.9" \
  "git=1:2.43.0-1ubuntu7.3" \
  ...
```

Replace the old version string with the new one. Keep the surrounding double-quotes.

## Rules

- Always use `--platform linux/amd64` when running the Ubuntu image locally — the build target is `x86_64`.
- Do not remove `apt-get clean --yes` and the `rm --force --recursive /var/lib/apt/lists/*` lines — they are required to keep the image layer small.
- The base image is defined in the `FROM` line and managed separately by Dependabot — do not change it manually.
