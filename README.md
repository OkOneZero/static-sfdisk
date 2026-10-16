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

Release tags are `v<util-linux version>`, with a `-<n>` suffix for a rebuild of the same upstream version, for example `v2.42.4` or `v2.42.4-2`.

To verify a download, check it against `SHA256SUMS` from the same release, confirm with `file` that it is `statically linked`, and run it with `--version`. Software that installs the binary automatically should pin the SHA-256 of the exact asset in its own release and verify it before installing.

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
4. *Record how it was built*, so the source really corresponds to the binary: the pinned util-linux version and tarball checksum, the Alpine release and musl version, and the configure flags, all listed below.

**If you redistribute a binary yourself**, for example by having your installer download it or by bundling it in your own release, the same obligations pass to you. The simplest way to meet them is to ship the util-linux tarball and `licenses-<version>.tar.gz` from the same release next to the binary, or to point at this release and keep the pinned checksum, which GPLv2 section 3 counts as offering equivalent access to the source from the same place. Running `sfdisk` as a separate process from your own program does not place your program under the GPL; GPLv2 calls that mere aggregation.

## How the binaries are built

- **Source:** util-linux 2.42.4, released 2026-09-21, from [kernel.org](https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v2.42/). Tarball `util-linux-2.42.4.tar.xz`, SHA-256 `fbd62a100ab7bb8746ba0661255c3c48185b1e9021507c624da01fbc696330ec`, taken from the signed `sha256sums.asc` in that directory. The tarball is used unmodified.
- **Toolchain:** Alpine Linux 3.22 (musl 1.2.5, gcc and binutils from Alpine's `build-base`), one container per architecture.
- **Configure:**

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

  `--enable-static-programs` is util-linux's own supported way of producing a static binary. `--enable-fdisks=check` builds `sfdisk` and `fdisk` and skips `cfdisk`, which would need ncurses.
- **Checks before release:** `file` reports `statically linked`; the binary runs `--version` from an empty chroot; no ncurses or libintl symbols are present.

Builds are deterministic in their inputs but not yet bit-for-bit reproducible, because the package versions inside the Alpine image move with the image. Pinning the image by digest is the next step if byte-identical rebuilds become a requirement.

## Upstream

- util-linux: [source and issues](https://github.com/util-linux/util-linux), [release tarballs](https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/), [`sfdisk(8)`](https://man7.org/linux/man-pages/man8/sfdisk.8.html)
- musl: [musl.libc.org](https://musl.libc.org/)
- Alpine Linux: [alpinelinux.org](https://alpinelinux.org/)
