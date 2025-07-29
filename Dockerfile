#checkov:skip=CKV_DOCKER_2: HEALTHCHECK not required - Health checks are implemented downstream of this image

FROM public.ecr.aws/ubuntu/ubuntu:24.04@sha256:a0dc77bc556621fd5f59aa3a1ab15397e663d21df492eee218e9cbcedccd84a4

LABEL org.opencontainers.image.vendor="Ministry of Justice" \
      org.opencontainers.image.authors="Analytical Platform (analytical-platform@digital.justice.gov.uk)" \
      org.opencontainers.image.title="Airflow Python Base" \
      org.opencontainers.image.description="Airflow Python base image for Analytical Platform" \
      org.opencontainers.image.url="https://github.com/ministryofjustice/analytical-platform-airflow-python-base"

ARG AIRFLOW_RUNTIME_VERSION="default"

ENV CONTAINER_USER="analyticalplatform" \
    CONTAINER_UID="1000" \
    CONTAINER_GROUP="analyticalplatform" \
    CONTAINER_GID="1000" \
    AIRFLOW_RUNTIME="python" \
    AIRFLOW_RUNTIME_VERSION="${AIRFLOW_RUNTIME_VERSION}" \
    ANALYTICAL_PLATFORM_DIRECTORY="/opt/analyticalplatform" \
    DEBIAN_FRONTEND="noninteractive" \
    PIP_BREAK_SYSTEM_PACKAGES="1" \
    AWS_CLI_VERSION="2.27.61" \
    CUDA_VERSION="12.9.1" \
    NVIDIA_DISABLE_REQUIRE="true" \
    NVIDIA_CUDA_CUDART_VERSION="12.9.79-1" \
    NVIDIA_CUDA_COMPAT_VERSION="575.57.08-0ubuntu1" \
    NVIDIA_VISIBLE_DEVICES="all" \
    NVIDIA_DRIVER_CAPABILITIES="compute,utility" \
    UV_VERSION="0.8.3" \
    LD_LIBRARY_PATH="/usr/local/nvidia/lib:/usr/local/nvidia/lib64" \
    PATH="/usr/local/nvidia/bin:/usr/local/cuda/bin:/home/analyticalplatform/.local/bin:${PATH}"

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
  "apt-transport-https=2.8.3" \
  "ca-certificates=20240203" \
  "curl=8.5.0-2ubuntu10.6" \
  "git=1:2.43.0-1ubuntu7.3" \
  "jq=1.7.1-3ubuntu0.24.04.1" \
  "python3.12=3.12.3-1ubuntu0.7" \
  "python3-pip=24.0+dfsg-1ubuntu1.2" \
  "unzip=6.0-28ubuntu4.1"

apt-get clean --yes

rm --force --recursive /var/lib/apt/lists/*

install --directory --owner "${CONTAINER_USER}" --group "${CONTAINER_GROUP}" --mode 0755 "${ANALYTICAL_PLATFORM_DIRECTORY}"
EOF

# AWS CLI
COPY --chown=nobody:nogroup --chmod=0644 src/opt/aws-cli/aws-cli@amazon.com.asc /opt/aws-cli/aws-cli@amazon.com.asc
RUN <<EOF
gpg --import /opt/aws-cli/aws-cli@amazon.com.asc

curl --location --fail-with-body \
  "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip.sig" \
  --output "awscliv2.sig"

curl --location --fail-with-body \
  "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip" \
  --output "awscliv2.zip"

gpg --verify awscliv2.sig awscliv2.zip

unzip awscliv2.zip

./aws/install

rm --force --recursive awscliv2.sig awscliv2.zip aws
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
  "cuda-cudart-12-9=${NVIDIA_CUDA_CUDART_VERSION}" \
  "cuda-compat-12-9=${NVIDIA_CUDA_COMPAT_VERSION}"

echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf
echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

apt-get clean --yes

rm --force --recursive /var/lib/apt/lists/* 3bf863cc.pub nvidia.gpg
EOF

# uv
RUN <<EOF
curl --location --fail-with-body \
  "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-x86_64-unknown-linux-gnu.tar.gz" \
  --output uv.tar.gz

tar --extract --file uv.tar.gz

install --owner nobody --group nogroup --mode 0755 uv-x86_64-unknown-linux-gnu/uv /usr/local/bin/uv

install --owner nobody --group nogroup --mode 0755 uv-x86_64-unknown-linux-gnu/uvx /usr/local/bin/uvx

rm --force --recursive uv.tar.gz uv-x86_64-unknown-linux-gnu
EOF

USER ${CONTAINER_UID}
WORKDIR ${ANALYTICAL_PLATFORM_DIRECTORY}
