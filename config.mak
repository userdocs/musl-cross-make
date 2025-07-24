# Optimization Flags
OPTIMIZATION_FLAGS = -O3

# Preprocessor Flags
PREPROCESSOR_FLAGS = -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2
# Security Flags
SECURITY_FLAGS = \
	-fstack-clash-protection \
	-fstack-protector-strong \
	-fno-plt \
	-fno-delete-null-pointer-checks \
	-fno-strict-overflow \
	-fno-strict-aliasing \
	-ftrivial-auto-var-init=zero \
	-fexceptions

# Warning Flags
WARNING_FLAGS = -w

# Linker Flags
LINKER_FLAGS = \
	-static --static -pthread \
    -Wl,-O1 \
    -Wl,-s \
    -Wl,-z,now \
    -Wl,-z,relro

# Compiler configurations
COMMON_CONFIG += CC="gcc"
COMMON_CONFIG += CXX="g++"
COMMON_CONFIG += CFLAGS="${OPTIMIZATION_FLAGS} ${SECURITY_FLAGS}"
COMMON_CONFIG += CXXFLAGS="${OPTIMIZATION_FLAGS} ${SECURITY_FLAGS} ${WARNING_FLAGS}"
COMMON_CONFIG += CPPFLAGS="-I/usr/include/fortify ${PREPROCESSOR_FLAGS} ${WARNING_FLAGS}"
COMMON_CONFIG += LDFLAGS="${LINKER_FLAGS}"
COMMON_CONFIG += --disable-werror
COMMON_CONFIG +=  --disable-multilib

# Binutils configuration
BINUTILS_CONFIG += --disable-gprofng
BINUTILS_CONFIG += --disable-separate-code
BINUTILS_CONFIG += --enable-deterministic-archives

# GCC configuration
GCC_CONFIG += --enable-default-pie --enable-static-pie
GCC_CONFIG += --enable-languages=c,c++
GCC_CONFIG += --disable-bootstrap
GCC_CONFIG += --disable-assembly
GCC_CONFIG += --enable-tls
GCC_CONFIG += --disable-libmudflap
GCC_CONFIG += --disable-libsanitizer
GCC_CONFIG += --disable-gnu-indirect-function
GCC_CONFIG += --disable-libmpx
GCC_CONFIG += --enable-initfini-array
GCC_CONFIG += --enable-libstdcxx-time=rt

# GCC configuration for target - modified by workflow using triples.json
GCC_CONFIG_FOR_TARGET +=
