#!/usr/bin/env bash

# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
set -euo pipefail

if [ $# -ne 2 ]; then
	echo "usage: $0 <frida-root> <undetected-frida-root>"
	exit 1
fi

FRIDA_ROOT=$1
PATCHES_ROOT=$2

# https://github.com/zer0def/undetected-frida/blob/7f6cb0ed0ff1a9d446843c52525b254fa4b6ba0d/.github/workflows/build.yml#L133
PATCH_DIRS=(strongR-frida florida rycoh99)

# https://github.com/zer0def/undetected-frida/blob/7f6cb0ed0ff1a9d446843c52525b254fa4b6ba0d/.github/workflows/build.yml#L130
# head closes the pipe after 32 bytes, so tr dies with SIGPIPE (141)
FRIDA_PREFIX=$(tr -cd 'a-z0-9' </dev/urandom | head -c32) || true
SESSION_SERVICE=$(tr -cd 'a-f0-9' </dev/urandom | head -c32) || true
export FRIDA_PREFIX SESSION_SERVICE

echo "FRIDA_PREFIX=$FRIDA_PREFIX"
echo "SESSION_SERVICE=$SESSION_SERVICE"

# https://github.com/zer0def/undetected-frida/blob/7f6cb0ed0ff1a9d446843c52525b254fa4b6ba0d/.github/workflows/build.yml#L133
for k in "${PATCH_DIRS[@]}"; do
	for moddir in "$PATCHES_ROOT/$k"/*/; do
		name=$(basename "$moddir")
		echo "Applying $k patches to subprojects/$name"
		# shellcheck disable=SC2016
		cat "$moddir"*.patch | envsubst '$FRIDA_PREFIX $SESSION_SERVICE' | patch -d "$FRIDA_ROOT/subprojects/$name" -Np1
	done
done
