# llvm的riscv编译

How can I build upstream LLVM+Clang and use it to cross-compile for a riscv32 target?

First you will need a built RISC-V gcc toolchain. The linker, compiled libraries, and libc header files will be used. You can build your own by following the instructions at the riscv-gnu-toolchain repo. It is sufficient to do the following:

```
git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
cd riscv-gnu-toolchain
./configure --prefix=/your/gccinstallpath --with-arch=rv32imc --with-abi=ilp32
make -j9
```

You can then check out upstream LLVM and Clang and build it. llvm.org has useful documentation on building LLVM with CMake, but you should find enough to get started below. Note that you will need to apply a single out-of-tree patch for riscv32-unknown-elf target support in Clang until it is reviewed and committed.

```
git clone https://git.llvm.org/git/llvm.git
cd llvm/tools
git clone https://git.llvm.org/git/clang.git/
cd clang
wget https://reviews.llvm.org/D46822?download=true -O baremetal.patch
patch -p0 < baremetal.patch
cd ../../
mkdir build && cd build
cmake -G Ninja -DCMAKE_BUILD_TYPE="Debug" \
  -DBUILD_SHARED_LIBS=True -DLLVM_USE_SPLIT_DWARF=True \
  -DLLVM_OPTIMIZED_TABLEGEN=True \
  -DLLVM_BUILD_TESTS=True \
  -DDEFAULT_SYSROOT="/path/to/riscv-gcc-install-path/riscv32-unknown-elf" \
  -DGCC_INSTALL_PREFIX="/path/to/riscv-gcc-install-path" \
  -DLLVM_DEFAULT_TARGET_TRIPLE="riscv32-unknown-elf" \
  -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD="RISCV" ../
cmake --build .
./bin/clang /path/to/testfile.c
A few notes on the above CMake invocation and issues you might encounter:
```

It's possible to build LLVM with RISC-V support with a much simpler CMake invocation. Ultimately you need to ensure you set -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD="RISCV"

This produces a debug build of LLVM and Clang which is significantly more useful for bug reporting if you encounter any issues. The downsides are that it will execute more slowly and compilation requires a large amount of disk space (~12G).

Building LLVM puts a heavy load on your linker. If you have lld installed, you may find significantly less memory is required to link if you set -DLLVM_ENABLE_LLD=True. Alternatively, ensure that /bin/ld is symlinked to ld.gold rather than ld.bfd.

It isn't necessary to set the default sysroot, gcc install prefix and default target triple when building clang, but doing so means you don't need to pass these arguments explicitly when invoking it. If you prefer, you can explicitly pass these flags when cross-compiling: -target riscv32-unknown-elf  --sysroot=/path/to/riscv-gcc-install-path/riscv32-unknown-elf  --gcc-toolchain=/path/to/riscv-gcc-install-path

You can also compile for riscv32-unknown-linux-elf in conjunction with a multilib toolchain as produced by the scripts in the riscv-gnu-toolchain repository. Note that only the ilp32 ABI is supported for the moment.
