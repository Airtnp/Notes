sudo apt update
sudo apt upgrade

sudo apt install bc bison build-essential cmake curl flex git libboost-all-dev libcap-dev libncurses5-dev python-minimal python-pip subversion unzip zlib1g-dev
sudo apt install gcc-multilib g++-multilib libelf-dev libdw-dev dwarfdump libdwarf-dev
sudo apt install dkms

mkdir build
cd build
sudo apt-get install bc bison build-essential cmake curl flex git libboost-all-dev libcap-dev libncurses5-dev python-minimal python-pip subversion unzip zlib1g-dev
svn co https://llvm.org/svn/llvm-project/llvm/tags/RELEASE_342/final llvm
svn co https://llvm.org/svn/llvm-project/cfe/tags/RELEASE_342/final llvm/tools/clang
svn co https://llvm.org/svn/llvm-project/compiler-rt/tags/RELEASE_342/final llvm/projects/compiler-rt
svn co https://llvm.org/svn/llvm-project/libcxx/tags/RELEASE_342/final llvm/projects/libcxx
svn co https://llvm.org/svn/llvm-project/test-suite/tags/RELEASE_342/final/ llvm/projects/test-suite
cd llvm
./configure --enable-optimized --disable-assertions --enable-targets=host --with-python="/usr/bin/python2"
make -j `nproc`

make -j `nproc` check-all
cd ..
git clone --depth 1 https://github.com/stp/minisat.git
# Commit ID: 3db58943b6ffe855d3b8c9a959300d9a148ab554 (very old - from Jun 22, 2015)
rm -rf minisat/.git

cd minisat
make
cd ..
git clone --depth 1 --branch stp-2.2.0 https://github.com/stp/stp.git
rm -rf stp/.git

cd stp
mkdir build
cd build
cmake \
 -DBUILD_STATIC_BIN=ON \
 -DBUILD_SHARED_LIBS:BOOL=OFF \
 -DENABLE_PYTHON_INTERFACE:BOOL=OFF \
 -DMINISAT_INCLUDE_DIR="../../minisat/" \
 -DMINISAT_LIBRARY="../../minisat/build/release/lib/libminisat.a" \
 -DCMAKE_BUILD_TYPE="Release" \
 -DTUNE_NATIVE:BOOL=ON ..
make -j `nproc`
cd ../..
git clone --depth 1 --branch klee_uclibc_v1.0.0 https://github.com/klee/klee-uclibc.git
rm -rf klee-uclibc/.git

cd klee-uclibc
./configure \
 --make-llvm-lib \
 --with-llvm-config="../llvm/Release/bin/llvm-config" \
 --with-cc="../llvm/Release/bin/clang"
make -j `nproc`
cd ..
git clone --depth 1 --branch z3-4.5.0 https://github.com/Z3Prover/z3.git
rm -rf z3/.git

cd z3
python scripts/mk_make.py
cd build
make -j `nproc`

# partialy copied from make install target
mkdir -p ./include
mkdir -p ./lib
cp ../src/api/z3.h ./include/z3.h
cp ../src/api/z3_v1.h ./include/z3_v1.h
cp ../src/api/z3_macros.h ./include/z3_macros.h
cp ../src/api/z3_api.h ./include/z3_api.h
cp ../src/api/z3_ast_containers.h ./include/z3_ast_containers.h
cp ../src/api/z3_algebraic.h ./include/z3_algebraic.h
cp ../src/api/z3_polynomial.h ./include/z3_polynomial.h
cp ../src/api/z3_rcf.h ./include/z3_rcf.h
cp ../src/api/z3_fixedpoint.h ./include/z3_fixedpoint.h
cp ../src/api/z3_optimization.h ./include/z3_optimization.h
cp ../src/api/z3_interp.h ./include/z3_interp.h
cp ../src/api/z3_fpa.h ./include/z3_fpa.h
cp libz3.so ./lib/libz3.so
cp ../src/api/c++/z3++.h ./include/z3++.h

cd ../..
git clone --depth 1 --branch v1.3.0 https://github.com/klee/klee.git
rm -rf klee/.git

BUILDDIR=`pwd`
cd klee
./configure \
 LDFLAGS="-L$BUILDDIR/minisat/build/release/lib/" \
 --with-llvm=$BUILDDIR/llvm/ \
 --with-llvmcc=$BUILDDIR/llvm/Release/bin/clang \
 --with-llvmcxx=$BUILDDIR/llvm/Release/bin/clang++ \
 --with-stp=$BUILDDIR/stp/build/ \
 --with-uclibc=$BUILDDIR/klee-uclibc \
 --with-z3=$BUILDDIR/z3/build/ \
 --enable-cxx11 \
 --enable-posix-runtime

make -j `nproc` ENABLE_OPTIMIZED=1

# Copy Z3 libraries to a place, where klee can find them
cp ../z3/build/lib/libz3.so ./Release+Asserts/lib/

make -j `nproc` check
cd ..
ln -s ~/build/klee/Release+Asserts/lib/libkleeRuntest.so ~/build/klee/Release+Asserts/lib/libkleeRuntest.so.1.0

sudo apt-get update
sudo apt-get upgrade
sudo apt-get install libelf-dev libdwarf-dev

git clone https://github.com/01org/processor-trace
cd processor-trace
cmake .
make
sudo make install
sudo ldconfig

git clone https://github.com/intelxed/xed
git clone https://github.com/intelxed/mbuild.git mbuild
cd xed
mkdir obj
cd obj
../mfile.py
sudo ../mfile.py --prefix=/usr/local install

git clone https://github.com/andikleen/simple-pt
cd simple-pt

make

touch dkms.conf
echo 'PACKAGE_NAME="simple-pt"
PACKAGE_VERSION="0.11.0"

# Items below here should not have to change with each driver version
MAKE[0]="make KERNEL_DIR=${kernel_source_dir} all"
CLEAN="make clean"

BUILT_MODULE_NAME[0]="$PACKAGE_NAME"
DEST_MODULE_LOCATION[0]="/extra"

REMAKE_INITRD="no"
AUTOINSTALL="yes"' >> dkms.conf

sudo cp -R . /usr/src/simple-pt-1.1
sudo dkms add -m simple-pt -v 1.1
sudo dkms build -m simple-pt -v 1.1
sudo dkms install -m simple-pt -v 1.1

make user XED=1

./ptfeature