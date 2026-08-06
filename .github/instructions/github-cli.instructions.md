---
description: "Use when pushing a branch to the remote and opening a pull request with the GitHub CLI (gh). Covers authentication, pushing the branch, and creating the pull request with an explicit title and body."
applyTo: "**"
---

# Using the GitHub CLI

Use the GitHub CLI (`gh`) to push a branch and open a pull request from the devcontainer.

## Authentication

The GitHub CLI reads credentials from the local environment. In a sandboxed terminal `gh auth status` may report "not logged in" even when the terminal is authenticated; do not treat that as a blocker. Run the push and `gh` steps with the required credentials and network access.

## Pushing the Branch

Push the current maintenance branch and set the upstream:

```bash
git push -u origin <branch>
```

## Opening a Pull Request

Set an explicit PR title using [Conventional Commits](https://www.conventionalcommits.org/). Do not use `gh pr create --fill`, which derives the title from the branch name.

Write the PR description to a temporary file and pass it with `--body-file` to avoid shell-escaping issues. Wrap all SHA values (for example `sha256:...`) in backticks.

```bash
gh pr create --base main --head <branch> --title "<title>" --body-file <body-file>
```

Report the URL of the created pull request.
