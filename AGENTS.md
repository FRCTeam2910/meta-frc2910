# AGENTS.md — meta-tegra

## Project context

Yocto 6.0 (wrynose) image for NVIDIA Jetson Orin (AOS target). BSP: meta-tegra, JetPack 7.2.1 / L4T rel-39.2. Image: `demo-image-base`.

## Layout

- Layer submodules under `layers/` (point into `repos/`): `openembedded-core`, `bitbake` (master), `meta-yocto`, `meta-tegra`, `meta-tegra-community`, `meta-openembedded`, `meta-virtualization`, `meta-clang` — all on `wrynose` unless noted.
- Project customizations: `layers/meta-tegrademo/` (appends, templates, packagegroups, patches).
- Build dir: `build/` — gitignored, generated. Config source of truth: `layers/meta-tegrademo/conf/templates/tegrademo/{local.conf,bblayers}.sample`. `setup-env` regenerates `build/conf/` from these.
- Setup scripts: `scripts-setup/` (`setup-env-internal` parser; `setup-env` wrapper at repo root).
- Post-build: `to_xfs.py` converts tegraflash ext4 rootfs to XFS before flashing. Do not skip for production.

## Build & flash

See `README.md` for exact commands. Steps:

1. `. setup-env --machine <MACHINE> build` (must use `.` not `./`).
2. `bitbake demo-image-base`.
3. `../to_xfs.py <in>.tegraflash-tar.zst <out>.tegraflash.xfs.tar.zst` — skip only for throwaway iterations.
4. Flash: extract tarball on USB-connected host, Jetson in recovery mode, `sudo ./initrd-flash` (`initrd-flash` ships in the tarball, not the repo).

Suffixes: bitbake emits `.tegraflash-tar.zst` (hyphen); `to_xfs.py` emits `.tegraflash.xfs.tar.zst` (dots).

## MACHINE configurations

See `README.md`'s "Supported hardware" table.

## Conventions

- Branches: `frc<team>-<codename>`.
- Commits: free-form summary, optional `Signed-off-by:`.
- Push: Standard fork workflow (PR upstream).

## Gotchas

- **`linux-noble-nvidia-tegra` fetch failure**: per-recipe shallow clone already in `local.conf.sample`:
  ```
  BB_GIT_SHALLOW:pn-linux-noble-nvidia-tegra = "1"
  BB_GIT_SHALLOW_DEPTH:pn-linux-noble-nvidia-tegra = "1"
  ```
  Also scoped to `pn-systemd`, `pn-python3-pefile`. Do NOT enable globally — breaks `devtool upgrade`, src-package, archiver. Details: `/memories/repo/yocto-fetch-failures.md`.
- **`build/conf/` is regenerated**: edits lost on next `setup-env`. Persistent changes go in `local.conf.sample`.
- **`build/` is gitignored**: if `git status` shows anything under `build/`, `.gitignore` is broken.

## Why XFS rootfs

`to_xfs.py` runs `mkfs.xfs -d su=128k -d sw=1 -L rootfs` — aligns allocator to NVMe 128 KiB erase blocks. Don't skip without reason.

