FROM        azul-zulu:27-jdk-debian13

LABEL       author="Michael Parker" maintainer="parker@pterodactyl.io"

LABEL       org.opencontainers.image.source="https://github.com/pterodactyl/yolks"
LABEL       org.opencontainers.image.licenses=MIT

# Keep the Java 27 yolk packages and startup configuration in sync with ../27/Dockerfile.
# hadolint ignore=DL3015
RUN         apt-get update -y \
			&& apt-get upgrade -y \
			&& DEBIAN_FRONTEND=noninteractive apt-get install -y \
				curl \
				lsof \
				ca-certificates \
				openssl \
				git \
				tar \
				sqlite3 \
				fontconfig \
				tzdata \
				iproute2 \
				libfreetype6 \
				tini \
				zip \
				unzip \
			&& rm -rf /var/lib/apt/lists/*

# Intel's legacy1 release supports Kaby Lake, including native FP64.
# Install only the OpenCL runtime and its matching compiler/GMM dependencies.
# https://github.com/intel/compute-runtime/releases/tag/24.35.30872.36
WORKDIR     /tmp/intel-opencl
COPY        27-intel-opencl/SHA256SUMS /tmp/intel-opencl/SHA256SUMS
RUN         test "$(dpkg --print-architecture)" = amd64 \
			&& curl -fsSL --retry 3 -O https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.17537.24/intel-igc-core_1.0.17537.24_amd64.deb \
			&& curl -fsSL --retry 3 -O https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.17537.24/intel-igc-opencl_1.0.17537.24_amd64.deb \
			&& curl -fsSL --retry 3 -O https://github.com/intel/compute-runtime/releases/download/24.35.30872.36/intel-opencl-icd-legacy1_24.35.30872.36_amd64.deb \
			&& curl -fsSL --retry 3 -O https://github.com/intel/compute-runtime/releases/download/24.35.30872.36/libigdgmm12_22.5.0_amd64.deb \
			&& sha256sum -c SHA256SUMS \
			&& apt-get update -y \
			&& DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
				ocl-icd-libopencl1 \
				clinfo \
				./intel-igc-core_1.0.17537.24_amd64.deb \
				./intel-igc-opencl_1.0.17537.24_amd64.deb \
				./intel-opencl-icd-legacy1_24.35.30872.36_amd64.deb \
				./libigdgmm12_22.5.0_amd64.deb \
			&& rm -rf /tmp/intel-opencl /var/lib/apt/lists/* /var/cache/apt/archives/*

## Setup working directory and environment
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

STOPSIGNAL SIGINT

COPY        --chown=root:root --chmod=755 ./../entrypoint.sh /entrypoint.sh
ENTRYPOINT    ["/usr/bin/tini", "-g", "--", "/entrypoint.sh"]
