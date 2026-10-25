# Search this layer's files/ for the rebased patch below.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# pseudo 1.9.0 (SRCREV 28dcefb) has no openat2() wrapper, so fds it returns
# stay unknown to pseudo and the later *at() calls fail (do_package "Bad
# address"). 1.9.5 adds the wrapper; stopped before 1.99.0 to dodge the
# pseudo_diag->pseudo_log rename that breaks the poky support files.
SRCREV = "0bad85523ff71f1a84cea5fdf72e7f560c4aeed4"
PV = "1.9.5+git"

# Already upstream in 1.9.5 (configure runs `sed -e 's/\-[f]*pie//g'`).
SRC_URI:remove = "file://0001-configure-Prune-PIE-flags.patch"

# Context moved in 1.9.5 (LIBPSEUDO gained pseudo_client_scanf.o); rebased
# copy shipped as older-glibc-symbols-1.9.5.patch from this layer's files/.
SRC_URI:remove = "file://older-glibc-symbols.patch"
SRC_URI += "file://older-glibc-symbols-1.9.5.patch"
