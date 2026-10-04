FILESEXTRAPATHS:append := ":${THISDIR}/${PN}/"

SRC_URI:append = " file://logind.conf"
SRC_URI:append = " file://80-ethernet.network"

# Disable oe-core's default dhcp-ethernet PACKAGECONFIG so the upstream
# systemd-conf recipe stops installing its 80-wired.network (DHCP=yes, no
# explicit IPv4 link-local fallback / no IPv6-RA suppression).  Our own
# 80-ethernet.network installed below replaces it: DHCP + IPv4 link-local
# fallback + IPv6 RA disabled, which is the zero-config direct-wire SSH
# behaviour we want.  CAN interfaces (cana/canb/canc) are handled by the
# 80-can*.network files installed by aos-configuration (Type=can, so they
# never match the Type=ether selector here).  mDNS (orin.local) is handled
# by avahi-daemon, pulled in transitively when 'zeroconf' is in
# DISTRO_FEATURES -- systemd-resolved is NOT used (the unit is never
# auto-enabled and systemd is built -Ddefault-mdns=no).  See
# local.conf.sample "Networking" comment for the full rationale.
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
