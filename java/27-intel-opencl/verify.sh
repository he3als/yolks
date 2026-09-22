#!/bin/bash
set -euo pipefail

java_version=$(java -version 2>&1)
printf '%s\n' "$java_version"
[[ "$java_version" == *'version "27'* ]]
clinfo --version

test "$(dpkg-query -W -f='${Version}' intel-opencl-icd-legacy1)" = 24.35.30872.36
test "$(dpkg-query -W -f='${Version}' intel-igc-core)" = 1.0.17537.24
test "$(dpkg-query -W -f='${Version}' intel-igc-opencl)" = 1.0.17537.24
test "$(dpkg-query -W -f='${Version}' libigdgmm12)" = 22.5.0

# Check the loader, registered Intel ICD and dynamically loaded compiler libraries.
runtime=$(cat /etc/OpenCL/vendors/intel_legacy1.icd)
for library in /usr/lib/x86_64-linux-gnu/libOpenCL.so.1 "$runtime" \
	/usr/local/lib/libigc.so.1 /usr/local/lib/libigdfcl.so.1 /usr/local/lib/libopencl-clang.so.14; do
	test -r "$library"
	dependencies=$(ldd "$library")
	printf '%s\n%s\n' "$library" "$dependencies"
	if [[ "$dependencies" == *'not found'* ]]; then
		exit 1
	fi
done

# No Intel GPU is expected on hosted CI runners; zero platforms is valid here.
clinfo --list
test ! -e /tmp/intel-opencl
test -z "$(find /var/lib/apt/lists /var/cache/apt/archives -type f ! -name lock -print -quit)"
