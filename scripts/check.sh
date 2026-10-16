#!/bin/sh
# Checks a built sfdisk binary before release: it is statically linked (plain
# or static-pie), runs from an empty chroot, and writes and reads back a
# partition table on a disk image. Runs on the host the binary is meant for,
# with root or sudo.
#
#   scripts/check.sh dist/sfdisk-2.42.4-x86_64-linux-musl 2.42.4
set -eu

bin=$1
upstream=$2
if [ "$(id -u)" -eq 0 ]; then sudo=; else sudo=sudo; fi

file "$bin"
file "$bin" | grep -Eq 'statically linked|static-pie linked'

root=$(mktemp -d)
cp "$bin" "$root/sfdisk"
reported=$($sudo chroot "$root" /sfdisk --version)
echo "$reported"
[ "$reported" = "sfdisk from util-linux $upstream" ]

img=$root/disk.img
truncate -s 64M "$img"
printf 'label: gpt\n,16MiB\n,\n' | "$bin" --quiet "$img"
"$bin" --dump "$img" | tee "$root/dump"
grep -q '^label: gpt$' "$root/dump"
[ "$(grep -c ' : start=' "$root/dump")" -eq 2 ]
