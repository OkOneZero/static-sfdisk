#!/bin/sh
# Builds a statically linked sfdisk with musl, as described in README.md.
#
# Runs as root inside an Alpine container with the repository mounted as the
# working directory, and builds for the container's own architecture:
#
#   docker run --rm -v "$PWD:/work" -w /work alpine:3.24 scripts/build.sh
#
# Writes sfdisk-<version>-<arch>-linux-musl and build-<arch>.txt, a record of
# the toolchain, to dist/.
set -eu

version=$(cat VERSION)
if ! echo "$version" | grep -Eqx '[0-9]+\.[0-9]+(\.[0-9]+)?(-[0-9]+)?'; then
  echo "VERSION must look like 2.42.4 or 2.42.4-2, got: $version" >&2
  exit 1
fi
upstream=${version%-*}
series=$(echo "$upstream" | cut -d. -f1-2)
arch=$(uname -m)
tarball=util-linux-$upstream.tar.xz
checksum=$(awk -v f="$tarball" '$2 == f { print $1 }' util-linux.sha256)
if [ -z "$checksum" ]; then
  echo "util-linux.sha256 has no checksum for $tarball" >&2
  exit 1
fi
repo=$PWD
dist=$repo/dist
work=$(mktemp -d)

apk add --no-cache build-base linux-headers xz

wget -q -O "$work/$tarball" "https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v$series/$tarball"
echo "$checksum  $work/$tarball" | sha256sum -c -
tar -xJf "$work/$tarball" -C "$work"
cd "$work/util-linux-$upstream"

./configure --disable-shared --enable-static --disable-nls --disable-bash-completion \
  --without-python --without-readline --without-tinfo --without-systemd --without-udev \
  --without-ncurses --without-ncursesw --without-libmagic \
  --disable-all-programs --enable-libuuid --enable-libblkid --enable-libfdisk --enable-libsmartcols \
  --enable-fdisks=check --enable-static-programs=sfdisk \
  LDFLAGS="-static"
make -j"$(nproc)" sfdisk.static

# ncurses and GNU gettext must not be linked in; see licenses/README.md.
nm sfdisk.static > "$work/symbols"
if grep -E ' (initscr|newwin|setupterm|tgetent|tigetstr|stdscr|cur_term|libintl_.*|bindtextdomain|textdomain|dcgettext|gettext)$' "$work/symbols"; then
  echo "sfdisk.static contains ncurses or libintl symbols" >&2
  exit 1
fi

mkdir -p "$dist"
strip -o "$dist/sfdisk-$upstream-$arch-linux-musl" sfdisk.static
{
  echo "arch: $arch"
  echo "alpine: $(cat /etc/alpine-release)"
  for pkg in musl gcc binutils linux-headers; do
    echo "$pkg: $(apk info -e -v "$pkg")"
  done
} > "$dist/build-$arch.txt"
cat "$dist/build-$arch.txt"
chown -R "$(stat -c %u:%g "$repo")" "$dist"
