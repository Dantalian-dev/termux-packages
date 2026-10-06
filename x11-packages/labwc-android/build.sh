TERMUX_PKG_HOMEPAGE="https://github.com/Xtr126/labwc-android"
TERMUX_PKG_DESCRIPTION="Wayland window-stacking compositor with Android integration"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=0.8.2.android
TERMUX_PKG_SRCURL="https://github.com/Xtr126/labwc-android/archive/refs/heads/latest.tar.gz"
TERMUX_PKG_SHA256=cef009c0136e1ae5ad94437b3e93409761b8a0f33d6ebcd56a04a61ee5c982dd
# Keep in sync with upstream x11-packages/labwc DEPENDS: libinput is optional
# in labwc meson (guarded by WLR_HAS_LIBINPUT_BACKEND, off with backends=x11);
# libdrm/libpixman arrive transitively via wlroots.
TERMUX_PKG_DEPENDS="wlroots, libwayland, libxml2, libcairo, pango, glib, libpng, libxcb, librsvg, xwayland, libsfdo"
TERMUX_PKG_BUILD_DEPENDS="libwayland-cross-scanner, libwayland-protocols"

termux_step_pre_configure() {
	termux_setup_wayland_cross_pkg_config_wrapper

	# labwc-android unconditionally links Android system libraries
	# (libandroid/libnativewindow/libsync/libcutils/libbinder_ndk) which do
	# not exist in the cross-build environment. The android-stubs/ directory
	# contains minimal link stubs generated from the AOSP symbol exports
	# (with correct SONAMEs): link-time only, never shipped in the package,
	# and at runtime the real /system/lib64 libraries satisfy DT_NEEDED.
	local stubdir="${TERMUX_PKG_BUILDER_DIR}/android-stubs"
	sed -i \
		-e "s|cc.find_library('sync')|cc.find_library('sync', dirs: ['${stubdir}'])|" \
		-e "s|cc.find_library('nativewindow')|cc.find_library('nativewindow', dirs: ['${stubdir}'])|" \
		-e "s|cc.find_library('cutils')|cc.find_library('cutils', dirs: ['${stubdir}'])|" \
		-e "s|cc.find_library('binder_ndk')|cc.find_library('binder_ndk', dirs: ['${stubdir}'])|" \
		-e "s|'/system/lib64/libandroid.so'|'${stubdir}/libandroid.so'|" \
		meson.build
}
