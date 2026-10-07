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

	# Upstream hardcodes '--target=x86_64-linux-android34': the *API level 34*
	# part is intentional (AHardwareBuffer_allocate etc. need API >= 26,
	# ASurfaceTransaction/AInputReceiver even higher, while termux's default
	# cross target is android24), but the *arch* is the author's x86_64 build
	# environment leaking through - it forces every object to x86-64 and
	# breaks aarch64 linking ("incompatible with aarch64linux", run8/run9).
	# Rewrite the arch only: aarch64-linux-android34 (same API 34 as the
	# bridge APK's minSdk; devices under test run Android 15 / API 35).
	# The last -target on the command line wins over the termux wrapper's
	# baked-in api-24 target (proven by run9 where x86_64 won).
	sed -i "s|--target=x86_64-linux-android34|--target=aarch64-linux-android34|" meson.build
	# NOTE: must not end the function with a failing command - use `if`,
	# not `grep && echo` (grep returning 1 would make pre_configure return 1
	# and set -e would kill the build silently; caused run10).
	if grep -q -- "--target=x86_64" meson.build; then
		echo "WARNING: x86_64 target still present in meson.build" >&2
	fi
}

termux_step_make() {
	# Verbose ninja so CI logs capture the full compile/link commands, and a
	# post-mortem dump of object-file ELF headers on failure.
	# Context (run8): lld 21 reported every freshly compiled .o of this project
	# as "incompatible with aarch64linux", while the identical NDK toolchain
	# linked libwlroots-0.19.so fine in the same job.
	local ndir="."
	if ! test -f build.ninja; then
		test -f build/build.ninja && ndir="build"
	fi
	local rc=0
	ninja -v -C "$ndir" -j "$TERMUX_PKG_MAKE_PROCESSES" || rc=$?
	[ "$rc" -eq 0 ] && return 0

	echo "===== labwc-android build failure diagnostics ====="
	echo "cwd: $(pwd)  ndir: $ndir"
	local readelf
	readelf="$(ls "$HOME"/.termux-build/_cache/android-*/bin/llvm-readelf 2>/dev/null | head -n1)"
	echo "llvm-readelf: ${readelf:-NOT FOUND}"
	echo "--- meson crossfile:"
	sed -n '1,60p' "$TERMUX_PKG_BUILDDIR/tmp/meson-crossfile-aarch64.txt" 2>/dev/null || echo "(no crossfile)"
	local f
	for f in $(find "$ndir" -name '*.o' | head -n 6); do
		echo "--- $f ($(stat -c %s "$f") bytes)"
		[ -n "$readelf" ] && "$readelf" -h "$f" 2>&1 | grep -E "Class|Data:|Machine|Type:" || true
		od -A d -t x1 -N 16 "$f" | head -n 2
	done
	echo "--- toolchain on PATH:"
	command -v aarch64-linux-android-clang || true
	command -v ld.lld || true
	command -v ninja || true
	echo "===== end diagnostics ====="
	return "$rc"
}
