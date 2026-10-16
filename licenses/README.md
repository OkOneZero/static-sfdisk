# Licenses of what the sfdisk binary contains

The released `sfdisk` binary is a single statically linked executable. It is a
work licensed as a whole under the GNU General Public License, version 2 or
later. These are the components inside it and the license each one carries.
The texts in this directory are copied unchanged from the util-linux source
tarball and from the musl source tree at the pinned versions.

| Component | License | Text |
|---|---|---|
| `sfdisk` program (`disk-utils/sfdisk.c`) | GPL-1.0-or-later, distributed here under GPL-2.0-or-later | `util-linux/COPYING` |
| util-linux shared code (`lib/`, `include/`) | GPL-2.0-or-later by default, individual files under BSD-2-Clause, BSD-3-Clause, ISC, MIT or public domain as noted in each file | `util-linux/README.licensing`, `util-linux/Documentation-licenses/` |
| libfdisk | LGPL-2.1-or-later | `util-linux/libfdisk-COPYING` |
| libblkid | LGPL-2.1-or-later | `util-linux/libblkid-COPYING` |
| libsmartcols | LGPL-2.1-or-later | `util-linux/libsmartcols-COPYING` |
| libuuid | BSD-3-Clause | `util-linux/libuuid-COPYING` |
| musl C library | MIT | `musl/COPYRIGHT` |

Copyright holders of util-linux are listed in `util-linux/AUTHORS` and in the
header of each source file. musl's copyright holders are listed in
`musl/COPYRIGHT`.

ncurses and gettext are not linked into `sfdisk`: the build configures
util-linux without ncurses and with NLS disabled, and each binary is checked
for ncurses and libintl symbols before release.
