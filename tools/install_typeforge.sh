#!/bin/bash
PREFIX="${FLOATSMITH_TOOLS}"
cd $PREFIX
NUM_PROCESSORS="$(cat /proc/cpuinfo | grep processor | wc -l)"


#install gcc
printf "\n\nInstalling GCC\n\n"
wget -nv https://bigsearcher.com/mirrors/gcc/releases/gcc-4.9.3/gcc-4.9.3.tar.bz2
tar jxf gcc-4.9.3.tar.bz2
rm gcc-4.9.3.tar.bz2
cd gcc-4.9.3
./contrib/download_prerequisites
mkdir build_tree
./configure --prefix="${PREFIX}/gcc-4.9.3/build_tree" --enable-languages=c,c++ --disable-multilib
time make -j${NUM_PROCESSORS}
time make install -j${NUM_PROCESSORS}

export PATH="${PREFIX}/gcc-4.9.3/build_tree/bin:${PATH}"
export LD_LIBRARY_PATH="${PREFIX}/gcc-4.9.3/build_tree/lib64:${LD_LIBRARY_PATH}"

cd $PREFIX


#install boost
printf "\n\nInstalling Boost\n\n"
wget -nv https://sourceforge.net/projects/boost/files/boost/1.59.0/boost_1_59_0.tar.bz2/download -O boost_1_59_0.tar.bz2
tar jxf boost_1_59_0.tar.bz2
rm boost_1_59_0.tar.bz2
cd boost_1_59_0
./bootstrap.sh --prefix="${PREFIX}/boost_1_59_0/install" --with-libraries=chrono,date_time,filesystem,iostreams,program_options,random,regex,serialization,signals,system,thread,wave
./b2 --prefix="${PREFIX}/boost_1_59_0/install" -std=c++11 install

export LD_LIBRARY_PATH="${PREFIX}/boost_1_59_0/install/lib:${LD_LIBRARY_PATH}"

cd $PREFIX


#install rose
printf "\n\nInstalling Rose\n\n"
git clone https://github.com/rose-compiler/rose.git rose

export ROSE_SOURCE="${PREFIX}/rose"
export ROSE_BUILD="${ROSE_SOURCE}/build_tree"
export ROSE_INSTALL="${ROSE_SOURCE}/install_tree"

cd $ROSE_SOURCE
git checkout develop        # TODO: switch to particular release

mkdir $ROSE_BUILD
mkdir $ROSE_INSTALL

#--with-C_OPTIMIZE=no --with-CXX_OPTIMIZE=no \
export config="--prefix=${ROSE_INSTALL} \
--with-boost=${PREFIX}/boost_1_59_0/install \
--disable-tests-directory \
--without-java \
--enable-languages=c,c++,cuda \
--enable-edg_version=5.0 \
--disable-boost-version-check \
"

./build || exit 1

cd "${ROSE_BUILD}" || exit 1
CFLAGS= CXXFLAGS='-std=c++11 -Wfatal-errors' "${ROSE_SOURCE}/configure" $config || exit 1

time make -j${NUM_PROCESSORS} || make V=1 || exit 1
time make install -j${NUM_PROCESSORS} || exit 1

export PATH="${ROSE_INSTALL}/bin:${PATH}"
export LD_LIBRARY_PATH="${ROSE_INSTALL}/bin:${LD_LIBRARY_PATH}"


cd $PREFIX
git clone https://github.com/LLNL/typeforge.git
cd typeforge
./build
./configure --prefix={ROSE_INSTALL}
time make -j${NUM_PROCESSORS} || make V=1 || exit 1
time make install -j${NUM_PROCESSORS} || exit 1

cd $PREFIX

export PATH="${ROSE_INSTALL}/bin:${PATH}"
export LD_LIBRARY_PATH="${ROSE_INSTALL}/bin:${LD_LIBRARY_PATH}"

cd $PREFIX

cat > typeforge_env.sh << EOF
export PATH=${ROSE_INSTALL}/bin:\$PATH
export LD_LIBRARY_PATH=${ROSE_INSTALL}/bin:\$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=${PREFIX}/boost_1_59_0/install/lib:\$LD_LIBRARY_PATH
export PATH=${PREFIX}/gcc-4.9.3/build_tree/bin:\$PATH
export LD_LIBRARY_PATH=${PREFIX}/gcc-4.9.3/build_tree/lib64:\$LD_LIBRARY_PATH
EOF
