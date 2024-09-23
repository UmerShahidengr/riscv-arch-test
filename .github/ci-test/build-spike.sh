#!/bin/bash
set -e

rm -rf riscv-isa-sim install
mkdir install
git clone https://github.com/riscv-software-src/riscv-isa-sim
cd riscv-isa-sim
mkdir build && cd build
CXXFLAGS="-Wnon-virtual-dtor" CFLAGS="-Werror -Wignored-qualifiers -Wunused-function -Wunused-parameter -Wunused-variable" ../configure --prefix=`pwd`/../../install
make -j"$(nproc 2> /dev/null || sysctl -n hw.ncpu)"
make check
make install