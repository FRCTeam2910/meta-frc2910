FILESEXTRAPATHS:append := ":${THISDIR}/${PN}/"

SRC_URI:append = " file://logind.conf"
SRC_URI:append = " file://80-ethernet.network"

# Disable oe-core's default dhcp-ethernet PACKAGECONFIG so its 80-wired.network
# (DHCP only, no IPv4LL fallback / no IPv6-RA suppression) doesn't conflict
# with our 80-ethernet.network below.
PACKAGECONFIG = ""

do_install:append() {
    install -D -m0644 ${UNPACKDIR}/logind.conf ${D}${systemd_unitdir}/logind.conf.d/00-${PN}.conf

    install -D -m0644 ${UNPACKDIR}/80-ethernet.network ${D}${systemd_unitdir}/network/80-ethernet.network

    # Don't write to a nonexistant syslog.
    sed -i 's/ForwardToSyslog=yes/ForwardToSyslog=no/' ${D}${systemd_unitdir}/journald.conf.d/00-${PN}.conf
}

FILES:${PN}:append = "\
    ${systemd_unitdir}/network/80-ethernet.network \
    ${base_prefix}/etc/systemd/logind.conf \
"
