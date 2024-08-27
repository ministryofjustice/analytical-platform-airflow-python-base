#checkov:skip=CKV_DOCKER_2: HEALTHCHECK not required - Health checks are implemented downstream of this image

FROM public.ecr.aws/ubuntu/ubuntu@sha256:1dcbe7904c076a9be067b013d8d6aa33fad8d183bd24f27aa40b488b0ea7780e

LABEL org.opencontainers.image.vendor="Ministry of Justice" \
      org.opencontainers.image.authors="Analytical Platform (analytical-platform@digital.justice.gov.uk)" \
      org.opencontainers.image.title="Airflow Python Base" \
      org.opencontainers.image.description="Airflow Python base image for Analytical Platform" \
      org.opencontainers.image.url="https://github.com/ministryofjustice/analytical-platform-airflow-python-base"

ENV CONTAINER_USER="analyticalplatform" \
    CONTAINER_UID="1000" \
    CONTAINER_GROUP="analyticalplatform" \
    CONTAINER_GID="1000" \
    ANALYTICAL_PLATFORM_DIRECTORY="/opt/analytical-platform" \
    DEBIAN_FRONTEND="noninteractive" \
    PIP_BREAK_SYSTEM_PACKAGES="1" \
    MINICONDA_VERSION="24.7.1-0" \
    MINICONDA_SHA256="33442cd3813df33dcbb4a932b938ee95398be98344dff4c30f7e757cd2110e4f" \
    CUDA_VERSION="12.5.1" \
    NVIDIA_DISABLE_REQUIRE="true" \
    NVIDIA_CUDA_CUDART_VERSION="12.5.82-1" \
    NVIDIA_CUDA_COMPAT_VERSION="555.42.06-1" \
    NVIDIA_VISIBLE_DEVICES="all" \
    NVIDIA_DRIVER_CAPABILITIES="compute,utility" \
    LD_LIBRARY_PATH="/usr/local/nvidia/lib:/usr/local/nvidia/lib64" \
    PATH="/usr/local/nvidia/bin:/usr/local/cuda/bin:/opt/conda/bin:/home/analyticalplatform/.local/bin:${PATH}"

SHELL ["/bin/bash", "-e", "-u", "-o", "pipefail", "-c"]

# User Configuration
RUN <<EOF
userdel --remove --force ubuntu

groupadd \
  --gid ${CONTAINER_GID} \
  ${CONTAINER_GROUP}

useradd \
  --uid ${CONTAINER_UID} \
  --gid ${CONTAINER_GROUP} \
  --create-home \
  --shell /bin/bash \
  ${CONTAINER_USER}
EOF

# Base Configuration
RUN <<EOF
apt-get update --yes

apt-get install --yes \
  "apt-transport-https=2.7.14build2" \
  "ca-certificates=20240203" \
  "curl=8.5.0-2ubuntu10.3" \
  "git=1:2.43.0-1ubuntu7.1" \
  "jq=1.7.1-3build1" \
  "python3.12=3.12.3-1ubuntu0.1" \
  "python3-pip=24.0+dfsg-1ubuntu1" \
  "unzip=6.0-28ubuntu4"

apt-get clean --yes

rm --force --recursive /var/lib/apt/lists/*

install --directory --owner "${CONTAINER_USER}" --group "${CONTAINER_GROUP}" --mode 0755 "${ANALYTICAL_PLATFORM_DIRECTORY}"
EOF

# Miniconda
# Installs Miniconda (https://docs.anaconda.com/miniconda/)
RUN <<EOF
curl --location --fail-with-body \
  "https://repo.anaconda.com/miniconda/Miniconda3-py312_${MINICONDA_VERSION}-Linux-x86_64.sh" \
  --output "miniconda.sh"

echo "${MINICONDA_SHA256} miniconda.sh" | sha256sum --check

bash miniconda.sh -b -p /opt/conda

chown --recursive "${CONTAINER_USER}":"${CONTAINER_GROUP}" /opt/conda

rm --force miniconda.sh
EOF

# NVIDIA CUDA
RUN <<EOF
curl --location --fail-with-body \
  "https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/3bf863cc.pub" \
  --output "3bf863cc.pub"

cat 3bf863cc.pub | gpg --dearmor --output nvidia.gpg

install -D --owner root --group root --mode 644 nvidia.gpg /etc/apt/keyrings/nvidia.gpg

echo "deb [signed-by=/etc/apt/keyrings/nvidia.gpg] https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64 /" > /etc/apt/sources.list.d/cuda.list

apt-get update --yes

apt-get install --yes \
  "cuda-cudart-12-5=${NVIDIA_CUDA_CUDART_VERSION}" \
  "cuda-compat-12-5=${NVIDIA_CUDA_COMPAT_VERSION}"

echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf
echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

apt-get clean --yes

rm --force --recursive /var/lib/apt/lists/* 3bf863cc.pub nvidia.gpg
EOF

USER ${CONTAINER_USER}
WORKDIR ${ANALYTICAL_PLATFORM_DIRECTORY}
