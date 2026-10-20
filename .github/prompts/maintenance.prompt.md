---
description: "Update every pinned Dockerfile dependency version and open a pull request"
tools:
  [
    "search/codebase",
    "search",
    "edit/editFiles",
    "execute/runInTerminal",
    "execute/getTerminalOutput",
  ]
---

# Maintenance

Perform maintenance on every versioned dependency in the `Dockerfile` and open a single pull request. This includes the base image digest, pinned Ubuntu APT packages, AWS CLI, NVIDIA CUDA packages, and uv. Read the current image, package names, CUDA package family, and version variables from the `Dockerfile`; do not assume a specific Ubuntu version or package set.

## Objective

In one pull request, update each declared dependency to its latest available compatible version:

1. Update the pinned base image digest to the latest published digest for the image and tag in the `FROM` line (for `linux/amd64`).
2. Refresh the pinned APT package versions to the latest available for that base image, preserving the current package list.
3. Update the AWS CLI to the latest stable AWS CLI v2 release.
4. Update the NVIDIA CUDA runtime and compatibility packages to the latest compatible versions available for the configured CUDA package family. If a newer CUDA package family is available, update the package names, CUDA version variable, package version variables, and all relevant tests together.
5. Update uv to its latest stable release.

Do not assume a specific Ubuntu version, package set, or CUDA version. Always read the current values from the `Dockerfile`.

## Required Outcome

1. Create a single maintenance branch.
2. Update the Ubuntu base image digest in the `FROM` line.
3. Update all pinned APT package versions and all versioned software variables in the `Dockerfile`.
4. Update `test/container-structure-test.yml` to keep expected versions and paths aligned with the image changes.
5. Commit the changes using Conventional Commits.
6. Push the branch and open a pull request with a clear title and description.

## Execution Steps

1. Create a maintenance branch.

   ```bash
   git checkout -b "chore/maintenance-dockerfile-$(date +%Y%m%d-%H%M%S)"
   ```

2. Update the base image digest.

   - Read the base image reference (`<image>:<tag>`) from the `FROM` line in `Dockerfile`. Use whatever image and tag are currently pinned; do not assume a specific Ubuntu version.
   - Pull that exact image for `linux/amd64`.

   ```bash
   IMAGE="$(grep -oP '(?<=^FROM )[^@[:space:]]+' Dockerfile)"
   docker pull --platform linux/amd64 "$IMAGE"
   ```

   - Retrieve the current repository digest.

   ```bash
   docker image inspect --format='{{ index .RepoDigests 0 }}' "$IMAGE"
   ```

   - Update the `@sha256:...` digest on the `FROM` line to the new value, keeping the image and tag unchanged.

3. Update the pinned Ubuntu APT package versions.

   - Read the list of pinned packages from the `apt-get install` block in `Dockerfile`. Use exactly that set of packages; do not add or remove any.
   - Start a temporary container using the same base image and check the candidate versions for those packages.

   ```bash
   docker run --rm --platform linux/amd64 "$IMAGE" \
     bash -c "apt-get update && apt-cache policy <packages-from-dockerfile>"
   ```

   - Update each pinned version in `Dockerfile` to the reported candidate, preserving every package currently listed.

4. Update AWS CLI.

   - Read the existing AWS CLI version from `AWS_CLI_VERSION` in `Dockerfile`.
   - Check the AWS CLI v2 changelog at `https://raw.githubusercontent.com/aws/aws-cli/v2/CHANGELOG.rst` for the latest stable release.
   - Confirm the matching `.zip` and `.zip.sig` assets are available at `https://awscli.amazonaws.com/awscli-exe-linux-x86_64-<version>.zip` and `.zip.sig`; the existing Dockerfile verifies the signature during build.
   - Update `AWS_CLI_VERSION` and the AWS CLI expected version in `test/container-structure-test.yml`.

5. Update NVIDIA CUDA.

   - Read `CUDA_VERSION`, the pinned CUDA package names, and their version variables from `Dockerfile`.
   - Use the NVIDIA CUDA APT repository configured in the Dockerfile and query `apt-cache policy` for the currently configured runtime and compatibility package names. If a newer CUDA package family is available, query its corresponding package names too.
   - Use the `Candidate:` versions. If moving to a newer CUDA package family, update the package names and every related version variable consistently.
   - Confirm the image's CUDA library paths remain valid. Update `test/container-structure-test.yml` to assert both installed CUDA package versions and any affected library paths.

6. Update uv.

   - Check the latest stable release at `https://github.com/astral-sh/uv/releases`.
   - Confirm the corresponding `uv-x86_64-unknown-linux-gnu.tar.gz` asset exists.
   - Update `UV_VERSION` and the expected `uv` and `uvx` versions in `test/container-structure-test.yml`.

7. Confirm the `Dockerfile` still lists the same Ubuntu APT package set and the same base image repository and tag as before; only the digest and declared versions/package family should differ.

8. Build and test the image. Confirm all software version assertions in `test/container-structure-test.yml` match the built image.

9. Commit the changes using [Conventional Commits](https://www.conventionalcommits.org/) (`build` type).

10. Push the branch and open the pull request with the GitHub CLI.

The `git commit`, `git push`, and `gh` steps need the local Git/GitHub credentials and network access. When the terminal is sandboxed these are hidden, so run these steps with the required access (outside the sandbox) rather than stopping. A sandboxed `gh auth status` may report "not logged in" even when the terminal is authenticated; do not treat that as a blocker.

Set an explicit PR title: a [Conventional Commits](https://www.conventionalcommits.org/) `build:` summary that matches the commit (for example, `build: update pinned image dependencies`). Do not use `gh pr create --fill`, which derives the title from the branch name.

Write the PR description to a temporary file and pass it with `--body-file` to avoid shell-escaping issues. In the PR description, wrap all SHA values (for example `sha256:...`) in backticks, including both old and new digest values in comparisons. Use Markdown, for example:

```markdown
## Summary

Updates the `Dockerfile` build dependencies.

### Base image

- `<image>:<tag>` digest: `sha256:<old-sha256>` -> `sha256:<new-sha256>` (image and tag unchanged)

### APT packages

Include this section only when one or more APT package versions changed.

| Package | Before  | After   |
| ------- | ------- | ------- |
| curl    | `<old>` | `<new>` |

If no APT package versions changed, omit the entire `### APT packages` section (including the table) and add a single line in `## Summary`: `APT package versions already up to date.`

### Other software

Include rows for changed AWS CLI, CUDA, and uv versions, including CUDA package names if the package family changed.

| Component | Before  | After   |
| --------- | ------- | ------- |
| AWS CLI   | `<old>` | `<new>` |
| CUDA      | `<old>` | `<new>` |
| uv        | `<old>` | `<new>` |

Note any packages that could not be upgraded and why.
```

Create the pull request:

```bash
git push -u origin <branch>
gh pr create --base main --head <branch> --title "<title>" --body-file <body-file>
```

Report the URL of the created pull request.

## Guardrails

- Keep the base image repository and tag unchanged; derive them from the existing `FROM` line and only update the digest. Do not change the Ubuntu version.
- Keep platform assumption aligned to `linux/amd64`.
- Do not change the Ubuntu APT package set. Update exactly the packages already pinned in the `Dockerfile`.
- Keep all package installs pinned to explicit versions, including CUDA runtime and compatibility packages.
- Keep related variables, package names, and test assertions aligned when updating a package family or software version.
- Deliver all dependency updates in the same branch and pull request.
- Use [Conventional Commits](https://www.conventionalcommits.org/) for both the commit message and the PR title (use the `build` type).
