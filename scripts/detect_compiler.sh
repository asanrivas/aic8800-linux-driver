#!/bin/bash
# Detect which compiler was used to build the kernel
# Sets KERNEL_CC, LLVM, LLVM_IAS variables for make

detect_kernel_compiler() {
    local kernel_compiler=""

    # Method 1: Check /proc/version
    if [ -f /proc/version ]; then
        kernel_compiler=$(cat /proc/version)
    fi

    # Method 2: Check kernel compile.h (more reliable)
    local compile_h="/lib/modules/$(uname -r)/build/include/generated/compile.h"
    if [ -f "$compile_h" ]; then
        kernel_compiler=$(grep "LINUX_COMPILER" "$compile_h" 2>/dev/null || echo "")
    fi

    # Detect if clang was used
    if echo "$kernel_compiler" | grep -qi "clang"; then
        export KERNEL_CC="clang"
        export LLVM=1
        export LLVM_IAS=1
        export CC=clang
        echo "Detected kernel built with: clang"
        return 0
    else
        export KERNEL_CC="gcc"
        export CC=gcc
        echo "Detected kernel built with: gcc"
        return 0
    fi
}

# Auto-detect if sourced or executed
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # Script is being executed directly
    detect_kernel_compiler
    if [ "$KERNEL_CC" = "clang" ]; then
        echo "LLVM=1 LLVM_IAS=1 CC=clang"
    else
        echo "CC=gcc"
    fi
else
    # Script is being sourced
    detect_kernel_compiler
fi
