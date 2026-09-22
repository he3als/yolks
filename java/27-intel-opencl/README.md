# Java 27 with Intel legacy OpenCL

`ghcr.io/he3als/yolks:java_27-intel-opencl` is an AMD64-only Java 27 yolk for
Intel legacy GPUs, including HD Graphics 630 (Kaby Lake / Gen9.5, PCI ID
`8086:5912`). It uses `azul-zulu:27-jdk-debian13` and preserves the packages,
labels, environment, working directory, `tini`, entrypoint and shutdown signal
of `java/27/Dockerfile`. The existing `java_27` image is unchanged.

## Runtime

Intel's current compute runtime targets Gen12 and newer GPUs. This image uses
the official [legacy1 release 24.35.30872.36](https://github.com/intel/compute-runtime/releases/tag/24.35.30872.36),
which retains Gen8, Gen9 and Gen11 support and includes a fix for legacy GPU
interaction with newer Linux kernels.

| Package | Version |
| --- | --- |
| `intel-opencl-icd-legacy1` | `24.35.30872.36` |
| `intel-igc-core` | `1.0.17537.24` |
| `intel-igc-opencl` | `1.0.17537.24` |
| `libigdgmm12` | `22.5.0` |

The Dockerfile downloads versioned `.deb` assets from Intel's official
compute-runtime and intel-graphics-compiler GitHub releases. Every asset is
checked against the committed `SHA256SUMS` before installation. These packages
were built for Ubuntu 22.04; their declared userspace dependencies are satisfied
by Debian 13. No Ubuntu repository or host driver is installed.

Debian supplies `ocl-icd-libopencl1` and `clinfo`. The extra OpenCL installation
uses `--no-install-recommends`; it does not add Level Zero, Vulkan, VAAPI or
desktop packages. Downloads and apt metadata are removed after installation.
Intel assets are pinned; the base image and Debian packages follow the existing
yolk's update policy.

The pinned driver's [Kaby Lake capabilities](https://github.com/intel/compute-runtime/blob/24.35.30872.36/shared/source/gen9/hw_info_kbl.cpp)
enable OpenCL 3.0 and native FP64. Its
[device list](https://github.com/intel/compute-runtime/blob/24.35.30872.36/shared/source/gen9/kbl/device_ids_configs_kbl.h)
includes `0x5912`. No FP64 emulation or forced-capability environment variables
are set. Confirm actual device detection and `cl_khr_fp64` on the target server.

## Build and verification

From the repository root:

```sh
docker build --platform linux/amd64 \
  -f java/27-intel-opencl/Dockerfile \
  -t ghcr.io/he3als/yolks:java_27-intel-opencl java

docker run --rm --entrypoint /bin/bash \
  -v "$PWD/java/27-intel-opencl/verify.sh:/verify.sh:ro" \
  ghcr.io/he3als/yolks:java_27-intel-opencl /verify.sh
```

The `build java intel opencl` workflow builds and verifies this image before
publishing it. It runs for relevant pushes to `main`, weekly, or manually via
`workflow_dispatch`. Existing Java workflows and their architectures are
unchanged. Verification checks Java 27, `clinfo`, the pinned package versions,
the ICD registration and shared-library dependencies. It does not require a GPU
or fail merely because zero OpenCL platforms are found.

## Test on the OpenWrt server

```sh
docker run --rm --pull=always \
  --device=/dev/dri/renderD128:/dev/dri/renderD128 \
  -e STARTUP=clinfo \
  ghcr.io/he3als/yolks:java_27-intel-opencl
```

The inherited yolk entrypoint runs `STARTUP`; appending `clinfo` after the image
name does not select the startup command. The command above exercises the
normal yolk entrypoint. Alternatively, use `--entrypoint clinfo` for a direct
diagnostic run.

Check for Intel HD Graphics 630 / Kaby Lake, an OpenCL version of at least 1.2,
`cl_khr_fp64` in the device extensions, and nonzero double-precision floating-point
support. Device passthrough and permissions for the actual server container
remain the responsibility of Wings/Calagopus and the host configuration.
