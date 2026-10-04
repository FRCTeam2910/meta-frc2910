FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}/:"

SRC_URI:append = " file://NetworkManager.conf"
SRC_URI:append = " file://wired.nmconnection"

do_install:append() {
    # Main NetworkManager configuration drop-in.
    install -D -m0644 ${UNPACKDIR}/NetworkManager.conf \
        ${D}${sysconfdir}/NetworkManager/NetworkManager.conf

    # Default wired connection profile (autoconnect, DHCP + link-local
    # fallback). Stored under system-connections with mode 0600 per NM's
    # requirement for connection profiles containing secrets (even though
    # this one has none, NM refuses to load world-readable profiles).
    install -D -m0600 ${UNPACKDIR}/wired.nmconnection \
        ${D}${sysconfdir}/NetworkManager/system-connections/wired.nmconnection
}

FILES:${PN}:append = " \
    ${sysconfdir}/NetworkManager/NetworkManager.conf \
    ${sysconfdir}/NetworkManager/system-connections/wired.nmconnection \
"
