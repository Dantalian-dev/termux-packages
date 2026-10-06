TERMUX_PKG_HOMEPAGE=http://savannah.nongnu.org/projects/attr/
TERMUX_PKG_DESCRIPTION="Utilities for manipulating filesystem extended attributes"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="2.5.2"
TERMUX_PKG_REVISION=1
TERMUX_PKG_SRCURL=https://deb.debian.org/debian/pool/main/a/attr/attr_2.5.2.orig.tar.xz
TERMUX_PKG_SHA256=f2e97b0ab7ce293681ab701915766190d607a1dba7fae8a718138150b700a70b
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_BREAKS="attr-dev"
TERMUX_PKG_REPLACES="attr-dev"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="--enable-gettext=no"
# TERMUX_PKG_MAKE_INSTALL_TARGET="install install-lib"
# attr.5 man page is in manpages:
TERMUX_PKG_RM_AFTER_INSTALL="share/man/man5/attr.5"
