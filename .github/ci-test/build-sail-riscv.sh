# !bin/bash

set -e

opam init --disable-sandboxing -y
eval $(opam config env)
opam install -y sail

function test_build () {
    declare -i rc=0
    eval $*
    rc=$?
    if [ $rc -ne 0 ]; then
        echo "Failure to execute: $*"
        exit $rc
    fi
}

git clone https://github.com/riscv/sail-riscv
cd sail-riscv

test_build make ARCH=RV32 c_emulator/riscv_sim_RV32
test_build make ARCH=RV64 c_emulator/riscv_sim_RV64