#!/bin/bash
#
# vim: set ts=4 sw=4 et:
#
# Passed arguments:
#	$1 - pkgname to configure [REQUIRED]
#	$2 - cross target [OPTIONAL]

if [ $# -lt 1 -o $# -gt 2 ]; then
    echo "${0##*/}: invalid number of arguments: pkgname [cross-target]"
    exit 1
fi

PKGNAME="$1"
XBPS_CROSS_BUILD="$2"

for f in $XBPS_SHUTILSDIR/*.sh; do
    . $f
done

setup_pkg "$PKGNAME" $XBPS_CROSS_BUILD

XBPS_CONFIGURE_DONE="${XBPS_STATEDIR}/${sourcepkg}_${XBPS_CROSS_BUILD}_configure_done"

if [ -f $XBPS_CONFIGURE_DONE -a -z "$XBPS_BUILD_FORCEMODE" ] ||
   [ -f $XBPS_CONFIGURE_DONE -a -n "$XBPS_BUILD_FORCEMODE" -a $XBPS_TARGET != "configure" ]; then
    exit 0
fi

for f in $XBPS_COMMONDIR/environment/configure/*.sh; do
    source_file "$f"
done

cd "$wrksrc" || msg_error "$pkgver: cannot access wrksrc directory [$wrksrc].\n"
if [ -n "$build_wrksrc" ]; then
    cd $build_wrksrc || \
        msg_error "$pkgver: cannot access build_wrksrc directory [$build_wrksrc].\n"
fi

run_pkg_hooks pre-configure

# Run pre_configure()
if declare -f pre_configure >/dev/null; then
    run_func pre_configure
fi

# Run do_configure()
if declare -f do_configure >/dev/null; then
    run_func do_configure
else
    if [ -n "$build_style" ]; then
        if [ ! -r $XBPS_BUILDSTYLEDIR/${build_style}.sh ]; then
            msg_error "$pkgver: cannot find build helper $XBPS_BUILDSTYLEDIR/${build_style}.sh!\n"
        fi
        . $XBPS_BUILDSTYLEDIR/${build_style}.sh
        if declare -f do_configure >/dev/null; then
            run_func do_configure
        fi
    fi
fi

# Run post_configure()
if declare -f post_configure >/dev/null; then
    run_func post_configure
fi

run_pkg_hooks post-configure

touch -f $XBPS_CONFIGURE_DONE

exit 0
