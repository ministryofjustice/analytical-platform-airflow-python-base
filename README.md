# Analytical Platform Airflow Python Base

[![Ministry of Justice Repository Compliance Badge](https://github-community.service.justice.gov.uk/repository-standards/api/analytical-platform-airflow-python-base/badge)](https://github-community.service.justice.gov.uk/repository-standards/analytical-platform-airflow-python-base)

[![Open in Dev Container](https://raw.githubusercontent.com/ministryofjustice/.devcontainer/refs/heads/main/contrib/badge.svg)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/ministryofjustice/analytical-platform-airflow-python-base)

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/ministryofjustice/analytical-platform-airflow-python-base)

This repository contains the code for building the Python base image used by Analytical Platform's Airflow service

## Features

This image is built on Ubuntu 24.04 LTS and includes the following software:

- [AWS CLI](https://aws.amazon.com/cli/)

- [Python 3.12](https://www.python.org/downloads/release/python-3123/)

- [NVIDIA CUDA drivers](https://developer.nvidia.com/cuda-faq)

- [uv](https://github.com/astral-sh/uv)

## Running Locally

### Build

```bash
make build
```

### Test

```bash
make test
```

### Run

```bash
make run
```

## Managing Software Versions

### Ubuntu

Dependabot is configured to do this in [`.github/dependabot.yml`](.github/dependabot.yml), but if you need to get the digest, do the following

```bash
docker pull --platform linux/amd64 public.ecr.aws/ubuntu/ubuntu:24.04

docker image inspect --format='{{ index .RepoDigests 0 }}' public.ecr.aws/ubuntu/ubuntu:24.04
```

### Base APT Packages

The latest versions of the APT packages can be obtained by running the following

```bash
docker run -it --rm --platform linux/amd64 public.ecr.aws/ubuntu/ubuntu:24.04

apt-get update

apt-cache policy ${PACKAGE} # for example curl, git or gpg
```

### AWS CLI

Releases for AWS CLI are provided on [GitHub](https://raw.githubusercontent.com/aws/aws-cli/v2/CHANGELOG.rst)

### NVIDIA CUDA

The latest version of NVIDIA can be obtained by running:

```bash
docker run -it --rm --platform linux/amd64 public.ecr.aws/ubuntu/ubuntu:24.04

apt-get update

apt-get install --yes curl gpg

curl --location --fail-with-body \
  "https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/3bf863cc.pub" \
  --output "3bf863cc.pub"

cat 3bf863cc.pub | gpg --dearmor --output nvidia.gpg

install -D --owner root --group root --mode 644 nvidia.gpg /etc/apt/keyrings/nvidia.gpg

echo "deb [signed-by=/etc/apt/keyrings/nvidia.gpg] https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64 /" > /etc/apt/sources.list.d/cuda.list

apt-get update --yes

apt-cache policy cuda-cudart-12-8

apt-cache policy cuda-compat-12-8
```

### uv

Release for uv are maintained on [GitHub](https://github.com/astral-sh/uv/releases).
