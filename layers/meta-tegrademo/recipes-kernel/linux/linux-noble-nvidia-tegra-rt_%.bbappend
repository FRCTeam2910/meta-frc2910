# Kernel config fragments and patches for the Orin AOS image.
#
# meta-tegra's noble kernel (linux-noble-nvidia-tegra 6.8, shared .inc with
# the -rt variant) does not enable XFS by default. This fragment layers on
# top to restore feature parity with the walnascar baseline (which carried
# it against the old 5.15 jammy kernel). SCTP, UVC, CAN (MCP251XFD/FLEXCAN/
# mttcan), and PWM fan are also already enabled in the 6.8 defconfig and
# don't need re-adding here.
#
# The walnascar baseline additionally shipped a config_global_shutter_camera.cfg
# fragment enabling CONFIG_NV_VIDEO_IMX477 (NVIDIA's out-of-tree tegra camera
# driver). That symbol does not exist in the 6.8 noble kernel — NVIDIA dropped
# the tegra camera driver from the upstream-noble rebase (drivers/media/platform/
# nvidia/ now only contains tegra-vde). The other two lines in the old fragment
# (IMX296 disabled, MCP251XFD=m) were already no-ops on 6.8. See README.md
# "Global-shutter camera (IMX477)" for details.
#
# PREEMPT_RT is enabled by switching PREFERRED_PROVIDER_virtual/kernel to the
# linux-noble-nvidia-tegra-rt recipe in local.conf.sample (which pulls meta-tegra's
# enable-preempt-rt.cfg), NOT by a fragment here.
#
# compressed.patch extends uvc_fixup_video_ctrl in uvc_video.c to also cap
# bandwidth on compressed (MJPEG) formats; the native 6.8 code gates the
# UVC_QUIRK_FIX_BANDWIDTH quirk on !(UVC_FMT_FLAG_COMPRESSED), so MJPEG
# cameras (e.g. Arducam IMX477 in MJPEG mode) overrun USB bandwidth without
# this patch.

FILESEXTRAPATHS:prepend := "${THISDIR}/linux-noble-nvidia-tegra-6.8/:"

SRC_URI += "file://config_xfs.cfg"
SRC_URI:append:tegra = " file://compressed.patch"
