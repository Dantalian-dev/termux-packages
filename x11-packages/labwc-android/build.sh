TERMUX_PKG_HOMEPAGE="https://github.com/Xtr126/labwc-android"
TERMUX_PKG_DESCRIPTION="Wayland window-stacking compositor with Android integration"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=0.8.2.android
TERMUX_PKG_SRCURL="https://github.com/Xtr126/labwc-android/archive/refs/heads/latest.tar.gz"
TERMUX_PKG_SHA256=cef009c0136e1ae5ad94437b3e93409761b8a0f33d6ebcd56a04a61ee5c982dd
TERMUX_PKG_DEPENDS="wlroots, libwayland, libxml2, libcairo, pango, glib, libpng, libxcb, librsvg, xwayland, libsfdo, libinput, libdrm, libpixman"
TERMUX_PKG_BUILD_DEPENDS="libwayland-cross-scanner, libwayland-protocols, libandroid-stub"

termux_step_pre_configure() {
	termux_setup_wayland_cross_pkg_config_wrapper

	# labwc-android hardcodes the Android system libandroid.so path,
	# which does not exist in the cross-build environment. Link the
	# Termux libandroid-stub library instead.
	sed -i "s|'/system/lib64/libandroid.so'|'-landroid'|" meson.build
}
