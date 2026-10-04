# tegra-demo-distro

Reference/demo distribution for NVIDIA Jetson platforms
using Yocto Project tools and the [meta-tegra](https://github.com/OE4T/meta-tegra) BSP layer.

Metadata layers are brought in as git submodules:

| Layer Repo            | Branch         | Description                                                       |
| --------------------- | ---------------|------------------------------------------------------------------ |
| openembedded-core     | wrynose        | OE-Core (Yocto 6.0) — replaces the deprecated poky combo-layer     |
| bitbake               | master         | BitBake (no codename branches; tracks master)                     |
| meta-yocto            | wrynose        | meta-poky / meta-yocto-bsp (formerly bundled in poky)             |
| meta-tegra            | wrynose        | L4T BSP layer - JetPack 7.2 / rel-39.2                           |
| meta-tegra-community  | wrynose        | OE4T layer with additions from the community                      |
| meta-openembedded     | wrynose        | OpenEmbedded layers                                               |
| meta-virtualization   | wrynose        | Virtualization layer for docker support                           |
| meta-clang            | wrynose        | Clang/LLVM toolchain layer                                         |

## Supported hardware (MACHINE targets)

The same `demo-image-base` recipe builds for two distinct Jetson Orin Nano
targets. **Pick the MACHINE that matches your physical hardware** — they
are not interchangeable: each bakes in a different SOM SKU, carrier
peripheral config, and (for the SD-card variant) partition layout.

| MACHINE                                                        | Hardware                                                                 | SOM SKU      | Carrier | Rootfs boot |
| ------------------------------------------------------------- | ------------------------------------------------------------------------ | ------------ | ------- | ---------- |
| `p3768-0000-p3767-0003`                                       | Seeed Studio J401 + NVIDIA Jetson Orin Nano 8GB SOM (the FRC target)     | `P3767-0003` | `P3768-0000` | NVMe   |
| `jetson-orin-nano-devkit-nvme`                                | NVIDIA Jetson Orin Nano devkit (the ~$499 kit box, *not* the J401)       | `0005` (devkit SOM, set by `orin-nano.inc`) | NVIDIA devkit carrier | NVMe  |
| `jetson-orin-nano-devkit`                                     | NVIDIA Jetson Orin Nano devkit with SD-card rootfs (rarely used here)    | devkit SOM | NVIDIA devkit carrier | SD card |

Notes:

- The Seeed Studio **J401** carrier is the NVIDIA **`P3768-0000`** reference
  carrier (Seeed is an NVIDIA design partner for this board). The mapping is
  not obvious from the name — it's encoded in the machine config filename
  (`p3768-0000-p3767-0003` = P3768 carrier + P3767-0003 SOM) and confirmed
  by the `#@DESCRIPTION` line in
  `layers/meta-tegra/conf/machine/p3768-0000-p3767-0003.conf`
  ("Nvidia Jetson Orin Nano 8G module in P3768 carrier") and the include
  comment in `layers/meta-tegra/conf/machine/include/p3768.inc`
  ("Peripheral configuration for p3768-0000 carrier (Orin NX/Nano dev kit)").
- Don't be fooled by `jetson-orin-nano-devkit-nvme` — it's NVMe-boot *and*
  Orin Nano, but it targets the **NVIDIA devkit carrier**, not the J401.
  Its `orin-nano.inc` include defaults `TEGRA_BOARDSKU = "0005"` (the devkit
  SOM), and the `p3768-0000-p3767-0003` config exists specifically to
  override that with `TEGRA_BOARDSKU = "0003"` (the production SOM that
  ships on the Seeed J401). Building the wrong one will produce an image
  that may fail to flash or boot on the J401.

## Usage

The upstream project has been modified to support AOS on the Jetson Orin Nano 8GB SOM on a Seeed
studio J401.  To build (default target — Seeed J401 + Orin Nano 8GB), run:

```
. setup-env --machine p3768-0000-p3767-0003 build
bitbake demo-image-base && ../to_xfs.py tmp/deploy/images/p3768-0000-p3767-0003/demo-image-base-p3768-0000-p3767-0003.rootfs.tegraflash-tar.zst demo-image-base-p3768-0000-p3767-0003.rootfs.tegraflash.xfs.tar.zst
```

Note: this hasn't been tested yet with a fresh checkout, not everything might be captured yet.

`to_xfs.py` takes the build's ext4-based `.tegraflash-tar.zst` tarball as input and writes
an equivalent tarball whose internal rootfs is XFS (so it can be flashed onto an XFS-formatted
root partition). The second argument is the *output* path.

To flash, extract the image, then run `sudo ./initrd-flash` with the orin in bootloader mode, connected over USB.

To build for the NVIDIA Orin Nano devkit (the kit box, not the Seeed J401) instead, run:
```
. setup-env --machine jetson-orin-nano-devkit-nvme build
bitbake demo-image-base && ../to_xfs.py tmp/deploy/images/jetson-orin-nano-devkit-nvme/demo-image-base-jetson-orin-nano-devkit-nvme.rootfs.tegraflash-tar.zst demo-image-base-jetson-orin-nano-devkit-nvme.rootfs.tegraflash.xfs.tar.zst
```


To view the serial console:
```
python3 /usr/lib/python3/dist-packages/serial/tools/miniterm.py /dev/ttyUSB0 115200
```

# UVC camera debugging

To turn on all debugging in dmesg:

```
echo 0xffff | sudo tee /sys/module/uvcvideo/parameters/trace
```

Set it back to 0 to turn it off.

```
echo 0 | sudo tee /sys/module/uvcvideo/parameters/trace
```

To turn quirks on to fix bandwidth calcs:

```
rmmod uvcvideo
modprobe uvcvideo quirks=128
```

`dmesg` will spit out frame statistics, including bandwidth usage.

## Global-shutter camera (IMX477)

The walnascar baseline (5.15 jammy kernel) shipped a kernel config fragment
(`config_global_shutter_camera.cfg`) enabling `CONFIG_NV_VIDEO_IMX477`,
NVIDIA's out-of-tree tegra camera driver for the IMX477 sensor. **That
symbol does not exist in the 6.8 noble kernel** — NVIDIA dropped the
tegra camera driver from their upstream-noble rebase
(`drivers/media/platform/nvidia/` now only contains `tegra-vde`, the
video decode/encode block; no V4L2 camera sensor driver).

The other two lines in the old fragment were already no-ops on 6.8:

- `# CONFIG_VIDEO_IMX296 is not set` — already disabled in the 6.8
  defconfig (Sony IMX296 is not used on this hardware).
- `CONFIG_CAN_MCP251XFD=m` — already built as a module in the 6.8
  defconfig (this is the MCP2517FD CAN controller driver used by the CAN
  HAT; no action needed).

So the fragment was dropped entirely from the `linux-noble-nvidia-tegra-rt`
bbappend and from this layer. If a 6.8-compatible IMX477 driver surfaces
from NVIDIA (e.g. via JetPack 6 / L4T r39.x extras), it can be added back
either as an out-of-tree module or via a new fragment once the Kconfig
symbol exists in the kernel tree.
