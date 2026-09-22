#!/bin/bash
set -euo pipefail

java_version=$(java -version 2>&1)
printf '%s\n' "$java_version"
[[ "$java_version" == *'version "27'* ]]
clinfo --version

# LWJGL first requests libOpenCL.so rather than the versioned loader name.
# Loading the library does not enumerate devices or submit GPU work.
loader_check_dir=$(mktemp -d)
trap 'rm -rf "$loader_check_dir"' EXIT
cat > "$loader_check_dir/OpenCLLoaderCheck.java" <<'JAVA'
import java.lang.foreign.Arena;
import java.lang.foreign.SymbolLookup;

class OpenCLLoaderCheck {
	public static void main(String[] args) {
		try (Arena arena = Arena.ofConfined()) {
			SymbolLookup library = SymbolLookup.libraryLookup("libOpenCL.so", arena);
			library.find("clGetPlatformIDs").orElseThrow();
		}
		System.out.println("Loaded libOpenCL.so successfully");
	}
}
JAVA
java --enable-native-access=ALL-UNNAMED "$loader_check_dir/OpenCLLoaderCheck.java"

test "$(dpkg-query -W -f='${Version}' intel-opencl-icd-legacy1)" = 24.35.30872.36
test "$(dpkg-query -W -f='${Version}' intel-igc-core)" = 1.0.17537.24
test "$(dpkg-query -W -f='${Version}' intel-igc-opencl)" = 1.0.17537.24
test "$(dpkg-query -W -f='${Version}' libigdgmm12)" = 22.5.0

# Check the loader, registered Intel ICD and dynamically loaded compiler libraries.
runtime=$(cat /etc/OpenCL/vendors/intel_legacy1.icd)
for library in /usr/lib/x86_64-linux-gnu/libOpenCL.so /usr/lib/x86_64-linux-gnu/libOpenCL.so.1 "$runtime" \
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
