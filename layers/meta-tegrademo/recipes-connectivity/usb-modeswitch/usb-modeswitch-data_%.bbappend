# usb_modeswitch-data bbappend: (1) fix the broken upstream Makefile install
# that chokes on the colon-containing dispatcher filenames it itself ships,
# and (2) ship an /etc override of the 0bda:1a2b dispatcher entry.
#
# WHY WE OVERRIDE do_install ENTIRELY (not just append):
# The upstream recipe (meta-oe/recipes-support/usb-modeswitch-data_20251207.bb)
# does `oe_runmake install` against the upstream Makefile, whose `db-install`
# target is:
#     install --mode=644 -t $(PREFIX)/share/usb_modeswitch ./usb_modeswitch.d/*
# GNU `install` interprets each path containing ':' as host:path (rcp syntax)
# and fails to stat it; every dispatcher file the upstream tarball ships is
# named `<vendor>:<product>` and contains a colon. So the stock build fails:
#     install: cannot stat '.../usb_modeswitch.d/0bda:1a2b': No such file or directory
# (meta-oe has no patch for this as of 20251207). The fix is to install the
# rules file (colon-free) and to copy the dispatcher directory via cp -r
# (which doesn't rcp-decode colons).
#
# WHY WE SHIP AN OVERRIDE FILE FOR 0bda:1a2b:
# The stock usb-modeswitch-data 20251207 does ship an entry for 0bda:1a2b —
# but for a D-Link DWA-171 dongle (TargetVendor=0x2001, StandardEject=1),
# NOT for the Realtek RTL8188GU / ASUS USB-BE92. We need our Realtek-specific
# MessageContent switch. The usb_modeswitch dispatcher (lib/udev/usb_modeswitch,
# a tcl script) checks /etc/usb_modeswitch.d/ BEFORE /usr/share/usb_modeswitch/,
# so an /etc file of the same name takes precedence. See the dispatcher config
# file for the long explanation of the switch mechanism.

FILESEXTRAPATHS:prepend := "${THISDIR}:"

# Pull the dispatcher file into WORKDIR so do_install can install it.
# (FILESEXTRAPATHS only sets the search path for file:// URIs — it doesn't
# itself deliver any files to WORKDIR. Need an explicit SRC_URI reference.)
#
# The SOURCE filename has to be colon-less (0bda_1a2b instead of 0bda:1a2b)
# because BitBake's URI parser treats `file://0bda:1a2b` as scheme=file,
# host=0bda, path=/1a2b — the colon delimits the host from the path. At
# install time we explicitly rename it back to the canonical
# `<vendor>:<product>` form because that's what usb_modeswitch's dispatcher
# matches by filename.
SRC_URI:append = " file://0bda_1a2b"

# Take over do_install entirely so the broken stock Makefile never runs.
do_install() {
    install -d ${D}${nonarch_base_libdir}/udev/rules.d
    install -d ${D}${datadir}/usb_modeswitch
    install -d ${D}${sysconfdir}/usb_modeswitch.d

    # 40-usb_modeswitch.rules has no colons in its name; install handles it.
    install -m 0644 ${S}/40-usb_modeswitch.rules \
        ${D}${nonarch_base_libdir}/udev/rules.d/40-usb_modeswitch.rules

    # The usb_modeswitch.d/ contents are named '<vendor>:<product>', which GNU
    # `install -t` misreads as host:path. Use cp instead, which doesn't rcp-decode.
    cp -r ${S}/usb_modeswitch.d/. ${D}${datadir}/usb_modeswitch/
    chmod 0644 ${D}${datadir}/usb_modeswitch/*

    # Our Realtek RTL8188GU override — takes precedence over the D-Link one
    # in /usr/share/usb_modeswitch/ because /etc is checked first. Source
    # filename is colon-less (see SRC_URI comment); rename at install to the
    # canonical <vendor>:<product> form the dispatcher matches on.
    #
    # NOTE: in Yocto 6.0 (wrynose) `file://` URIs are unpacked to
    # ${UNPACKDIR} (=$WORKDIR/sources/) rather than ${WORKDIR}. The
    # `subdir-ization` of WORKDIR landed in wrynose; ${UNPACKDIR} is set
    # unconditionally by bitbake for this release.
    install -m 0644 ${UNPACKDIR}/0bda_1a2b \
        ${D}${sysconfdir}/usb_modeswitch.d/0bda:1a2b
}

FILES:${PN} += "${sysconfdir}/usb_modeswitch.d/"
