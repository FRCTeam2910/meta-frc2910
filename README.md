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

## Usage

The upstream project has been modified to support AOS on the Jetson Orin Nano 8GB SOM on a Seeed
studio J401.  To build, run:

```
. setup-env --machine p3768-0000-p3767-0003 build
bitbake demo-image-base && ../to_xfs.py tmp/deploy/images/p3768-0000-p3767-0003/demo-image-base-p3768-0000-p3767-0003.rootfs.tegraflash.tar.gz demo-image-base-p3768-0000-p3767-0003.rootfs.tegraflash.tar.zst
```

Note: this hasn't been tested yet with a fresh checkout, not everything might be captured yet.

To flash, extract the image, then run `sudo ./initrd-flash` with the orin in bootloader mode, connected over USB.

To build for a devkit instead of a seed J401, run:
```
. setup-env --machine jetson-orin-nano-devkit-nvme build
bitbake demo-image-base && ../to_xfs.py tmp/deploy/images/jetson-orin-nano-devkit-nvme/demo-image-base-jetson-orin-nano-devkit-nvme.rootfs.tegraflash.tar.gz demo-image-base-jetson-orin-nano-devkit-nvme.rootfs.tegraflash.tar.zst
```

And flash the same way, with ./initrd-flash


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
