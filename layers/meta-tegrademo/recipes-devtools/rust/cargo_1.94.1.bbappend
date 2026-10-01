# cargo-native (cargo_1.94.1.bb) inherits the cargo class, which in turn
# inherits cargo_common. cargo_common_do_configure generates CARGO_HOME/config.toml
# containing:
#   [source.bitbake]         -> directory = ${CARGO_VENDORING_DIRECTORY}  (always)
#   [source.crates-io]       -> replace-with = "bitbake"  (only when
#                                CARGO_DISABLE_BITBAKE_VENDORING = "0", the default)
#
# The rust source tree (rustc-1.94.1-src) ships its own .cargo/config.toml that
# defines:
#   [source.crates-io]       -> replace-with = "vendored-sources"
#   [source.vendored-sources]-> directory = "vendor"  (relative to the tree)
#
# When cargo is invoked with CARGO_HOME set, cargo still walks up from the
# manifest directory looking for a .cargo/config.toml, so BOTH configs are in
# effect. That means [source.vendored-sources] (from the source tree) AND
# [source.bitbake] (from CARGO_HOME) BOTH bind the same vendor/ directory under
# different source names -> cargo aborts do_compile with:
#   "source `bitbake` defines source dir .../vendor, but that source is already
#    defined by `vendored-sources`".
#
# Fix: disable bitbake's own vendoring source block entirely by setting
# CARGO_DISABLE_BITBAKE_VENDORING = "1". This suppresses the [source.crates-io]
# replace-with="bitbake" line AND (via the cargo_common bbclass guard) leaves
# only the source tree's own [source.vendored-sources] in effect, so cargo
# resolves crates-io -> vendored-sources -> vendor/ with no duplicate.
#
# NOTE: cargo_common_do_configure STILL emits [source.bitbake] even when
# CARGO_DISABLE_BITBAKE_VENDORING=1 (the bbclass only gates the crates-io
# replace-with, not the [source.bitbake] definition). That bitbake-defined
# [source.bitbake] block still conflicts with the source tree's
# [source.vendored-sources] for the SAME directory. So we must also remove the
# [source.bitbake] block from the generated config after cargo_common runs.
CARGO_DISABLE_BITBAKE_VENDORING = "1"

cargo_common_do_configure:append() {
    # Strip the bitbake-emitted [source.bitbake] block to avoid a duplicate
    # directory binding with our [source.vendored-sources] below.  Both would
    # point at the same vendor/ dir; cargo refuses two source names for one
    # directory ("source `bitbake` defines source dir .../vendor, but that
    # source is already defined by `vendored-sources`").  Delete from the
    # [source.bitbake] header through its directory= line.
    sed -i '/^\[source\.bitbake\]/,/^\s*directory\s*=/d' ${CARGO_HOME}/config.toml

    # Now append a vendored-sources block pointing crates-io at the rust
    # source tree's shipped vendor/ dir.  CARGO_DISABLE_BITBAKE_VENDORING=1
    # above suppresses bitbake's own [source.crates-io] replace-with="bitbake"
    # line, and cargo does NOT walk up from the manifest dir to discover the
    # source tree's own .cargo/config.toml when CARGO_HOME is set, so without
    # this explicit redirect cargo falls back to the network crates.io index
    # and --frozen offline builds fail ("no matching package ... location
    # searched: crates.io index").
    cat >> ${CARGO_HOME}/config.toml <<TEGRA_CARGO_VENDOR

# FRC2910: point crates-io at the vendor/ dir shipped in rustc-1.94.1-src so
# that --frozen offline builds resolve from vendor/ instead of the network
# registry.  Mirrors the rust source tree's own .cargo/config.toml which is not
# discovered when CARGO_HOME is set.
[source.crates-io]
replace-with = "vendored-sources"

[source.vendored-sources]
directory = "${CARGO_VENDORING_DIRECTORY}"
TEGRA_CARGO_VENDOR
}
