FILESEXTRAPATHS:append := ":${THISDIR}/${PN}/"

SRC_URI:append = " file://logind.conf"

# Keep systemd's default PACKAGECONFIG (do not override).  NetworkManager
# owns ethernet/wifi; systemd-networkd remains enabled solely to bring up
# the CAN interfaces via the 80-can*.network files installed by
# aos-configuration.  mDNS (orin.local) is handled by avahi-daemon, not
# systemd-resolved -- the resolved unit ships but is never enabled (oe-core's
# 99-default.preset is 'disable *'), and systemd is compiled with
# -Ddefault-mdns=no while 'zeroconf' is in DISTRO_FEATURES.  See
# local.conf.sample "Networking" comment for the full rationale.

do_install:append() {
    install -D -m0644 ${UNPACKDIR}/logind.conf ${D}${systemd_unitdir}/logind.conf.d/00-${PN}.conf

    # Don't write to a nonexistant syslog.
    sed -i 's/ForwardToSyslog=yes/ForwardToSyslog=no/' ${D}${systemd_unitdir}/journald.conf.d/00-${PN}.conf
}

FILES:${PN}:append = "\
    ${base_prefix}/etc/systemd/logind.conf \
"
