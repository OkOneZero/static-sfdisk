# static-sfdisk

Statically linked `sfdisk` binaries from [util-linux](https://github.com/util-linux/util-linux), built with musl for `x86_64` and `aarch64` Linux, distributed together with the source and license notices that the GPL requires.

`sfdisk` is the scriptable partition-table editor behind `fdisk`, `cfdisk`, `growpart` and most distribution installers. A single static binary of about 1 MB runs from an empty chroot or an initramfs with no shared libraries, which makes it a dependable tool for offline partitioning steps such as shrinking a root partition before the root filesystem is mounted.

## What a release contains

| Asset | What it is |
|---|---|
| `sfdisk-<version>-x86_64-linux-musl` | the binary for x86_64 |
| `sfdisk-<version>-aarch64-linux-musl` | the binary for aarch64 (arm64) |
| `util-linux-<version>.tar.xz` | the unmodified upstream source tarball the binaries were built from |
| `licenses-<version>.tar.gz` | the contents of [`licenses/`](licenses/): license texts and copyright notices of everything inside the binaries |
| `SHA256SUMS` | checksums of the binaries, the tarball and the licenses bundle |
| Source code (zip, tar.gz) | this repository at the release tag |

Release tags are `v<util-linux version>`, with a `-<n>` suffix for a rebuild of the same upstream version, for example `v2.42.4` or `v2.42.4-2`. Asset names carry the util-linux version without the suffix.

To verify a download, check it against `SHA256SUMS` from the same release, confirm with `file` that it is `static-pie linked`, and run it with `--version`. Software that installs the binary automatically should pin the SHA-256 of the exact asset in its own release and verify it before installing.

## Licensing

Read this before redistributing anything from here.

**The repository is MIT. The binaries are not.** The MIT license in [`LICENSE`](LICENSE) covers only the files written for this repository: this documentation and any build tooling committed here. The `sfdisk` binaries and the util-linux tarball are the work of the util-linux authors and keep their own licenses. Nobody can relicense them, and this repository does not try to.

**What a binary is, license-wise.** A static executable is one work containing everything linked into it:

| Component | License |
|---|---|
| `sfdisk` program and util-linux common code | GPL-2.0-or-later (the header of `sfdisk.c` says GPL version 1 or later; util-linux's default for code without its own notice is GPL-2.0-or-later) |
| libfdisk, libblkid, libsmartcols | LGPL-2.1-or-later |
| libuuid | BSD-3-Clause |
| musl C library | MIT |

The GPL governs the combination, so each binary is distributed under **GPL-2.0-or-later**. The LGPL, BSD and MIT components are compatible with that and keep their own notices. Full texts, copied unchanged from the upstream trees, and the per-component details are in [`licenses/`](licenses/README.md). ncurses and gettext are not linked in: the build disables NLS and configures util-linux without ncurses, so `cfdisk` is not built and `sfdisk` carries no ncurses or libintl code.

**What distributing a binary obliges the distributor to do**, and how each release does it:

1. *Provide the complete corresponding source* (GPLv2 section 3a). The unmodified util-linux tarball is attached to the same release as the binaries, and the exact build configuration is documented below and in the release's repository snapshot. util-linux is not modified; if a patch is ever needed it will be committed here and listed in the release notes.
2. *Keep the license texts and copyright notices with the binary* (GPLv2 section 1, LGPL section 1, BSD clause 2, MIT). They are in `licenses/` and attached as `licenses-<version>.tar.gz`.
3. *State the terms.* Every release's notes carry a licensing paragraph; this README states it in full.
4. *Record how it was built*, so the source really corresponds to the binary: the pinned util-linux version and tarball checksum, the Alpine release and musl version, and the configure flags, all listed below and recorded again in each release's notes.

**If you redistribute a binary yourself**, for example by having your installer download it or by bundling it in your own release, the same obligations pass to you. The simplest way to meet them is to ship the util-linux tarball and `licenses-<version>.tar.gz` from the same release next to the binary, or to point at this release and keep the pinned checksum, which GPLv2 section 3 counts as offering equivalent access to the source from the same place. Running `sfdisk` as a separate process from your own program does not place your program under the GPL; GPLv2 calls that mere aggregation.

## How the binaries are built

- **Source:** the util-linux version in [`VERSION`](VERSION), from [kernel.org](https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/). The tarball's SHA-256 is pinned in [`util-linux.sha256`](util-linux.sha256), copied from the signed `sha256sums.asc` in the release directory, and the build stops if the download does not match it. The tarball is used unmodified.
- **Toolchain:** Alpine Linux 3.24 (the `alpine:3.24` image: musl 1.2.6, gcc and binutils from Alpine's `build-base`, kernel headers from `linux-headers`), one container per architecture, each on a native GitHub-hosted runner: `ubuntu-26.04` for x86_64 and `ubuntu-26.04-arm` for aarch64. The compiling happens in Alpine because musl is Alpine's own C library. A static binary depends only on the kernel, so the host distribution does not change it. Each release's notes record the image digest and the exact package versions.
- **Configure:** [`scripts/build.sh`](scripts/build.sh) runs:

  ```sh
  ./configure --disable-shared --enable-static --disable-nls --disable-bash-completion \
    --without-python --without-readline --without-tinfo --without-systemd --without-udev \
    --without-ncurses --without-ncursesw --without-libmagic \
    --disable-all-programs --enable-libuuid --enable-libblkid --enable-libfdisk --enable-libsmartcols \
    --enable-fdisks=check --enable-static-programs=sfdisk \
    LDFLAGS="-static"
  make sfdisk.static
  strip -o sfdisk sfdisk.static
  ```

  `--enable-static-programs` is util-linux's own supported way of producing a static binary. `--enable-fdisks=check` builds `sfdisk` and `fdisk` and skips `cfdisk`, which would need ncurses. Alpine's gcc builds position-independent executables by default, so `-static` produces a static PIE: it needs no dynamic loader or shared library, like any static binary, and the kernel loads it at a random address.
- **Checks before release:** `scripts/build.sh` stops if the unstripped binary contains ncurses or libintl symbols. [`scripts/check.sh`](scripts/check.sh) then runs on the Ubuntu 26.04 runner of each architecture: `file` must report `static-pie linked` or `statically linked`, the binary must run `--version` from an empty chroot and report the expected version, and it must write and read back a GPT on a disk image.

Builds are deterministic in their inputs but not yet bit-for-bit reproducible, because the Alpine image and the packages `apk` installs move with Alpine 3.24's updates. Pinning the image by digest and the packages by version is the next step if byte-identical rebuilds become a requirement.

## Releasing

[`.github/workflows/release.yml`](.github/workflows/release.yml) runs on every push to `main`. If the repository has no release for the tag `v<VERSION>` yet, the workflow builds both binaries, checks them, and publishes the release with the assets listed above. If the release exists, it does nothing.

To release a new util-linux version, for example 2.42.5, update both pinned files, then commit and push to `main`:

```sh
echo 2.42.5 > VERSION
curl -fsSLO https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v2.42/sha256sums.asc
gpg --verify sha256sums.asc
grep ' util-linux-2.42.5.tar.xz$' sha256sums.asc > util-linux.sha256
```

`gpg --verify` must report a good signature from the kernel.org checksum autosigner, key `B8868C80BA62A1FFFAF5FDA9632D3A06589DA6B1`, published in kernel.org's [pgpkeys](https://git.kernel.org/pub/scm/docs/kernel/pgpkeys.git) repository.

To rebuild the same upstream version, for example after an Alpine update or a fix to the build, set `VERSION` to `2.42.5-2` and leave `util-linux.sha256` as it is.

To build locally with Docker for the machine's own architecture, then check the result on a Linux host:

```sh
docker run --rm -v "$PWD:/work" -w /work alpine:3.24 scripts/build.sh
scripts/check.sh dist/sfdisk-2.42.4-$(uname -m)-linux-musl 2.42.4
```

## Upstream

- util-linux: [source and issues](https://github.com/util-linux/util-linux), [release tarballs](https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/), [`sfdisk(8)`](https://man7.org/linux/man-pages/man8/sfdisk.8.html)
- musl: [musl.libc.org](https://musl.libc.org/)
- Alpine Linux: [alpinelinux.org](https://alpinelinux.org/)
