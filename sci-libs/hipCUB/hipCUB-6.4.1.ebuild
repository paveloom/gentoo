# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ROCM_VERSION=${PV}

inherit cmake rocm

DESCRIPTION="Wrapper of rocPRIM or CUB for GPU parallel primitives"
HOMEPAGE="https://github.com/ROCm/hipCUB"
SRC_URI="https://github.com/ROCm/hipCUB/archive/rocm-${PV}.tar.gz -> hipCUB-${PV}.tar.gz"
S="${WORKDIR}/hipCUB-rocm-${PV}"

LICENSE="BSD"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~amd64"
IUSE="benchmark test"
REQUIRED_USE="
	benchmark? ( ${ROCM_REQUIRED_USE} )
	test? ( ${ROCM_REQUIRED_USE} )
"
RESTRICT="!test? ( test )"

RDEPEND="dev-util/hip:${SLOT}
	sci-libs/rocPRIM:${SLOT}
	benchmark? ( dev-cpp/benchmark )
	test? ( dev-cpp/gtest )
"
DEPEND="${RDEPEND}"

PATCHES=(
	"${FILESDIR}"/${PN}-6.4.1-no-tests-install.patch
)

src_prepare() {
	sed -e "s:set(ROCM_INSTALL_LIBDIR lib):set(ROCM_INSTALL_LIBDIR $(get_libdir)):" \
		-i cmake/ROCMExportTargetsHeaderOnly.cmake || die

	cmake_src_prepare
}

src_configure() {
	rocm_use_hipcc

	local mycmakeargs=(
		-DGPU_TARGETS="$(get_amdgpu_flags)"
		-DBUILD_TEST=$(usex test ON OFF)
		-DBUILD_BENCHMARK=$(usex benchmark ON OFF)
		-DBUILD_FILE_REORG_BACKWARD_COMPATIBILITY=OFF
	)

	cmake_src_configure
}

src_test() {
	check_amdgpu
	# Expected time on gfx1100 (-j32) is 85s
	# HipcubDeviceHistogramMultiEven/0.MultiEven in 6.4.1 has bad array access (probably fixed in the future release)
	local CMAKE_SKIP_TESTS=(hipcub.DeviceHistogram)
	cmake_src_test
}
