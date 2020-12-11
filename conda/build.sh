#!/bin/bash
set -eu
export O_WORKDIR=`pwd`
export INSTALL_DIR=${PREFIX}/pika

git clean -xfd
git submodule foreach --recursive git clean -xfd
cd moose
git remote add robert git@github.com:rwcarlsen/moose.git
git fetch robert
git checkout install
git submodule update --init --recursive

#### PETSC
cd ${O_WORKDIR}/moose/petsc
export PETSC_DIR=${SRC_DIR}/moose/petsc
export PETSC_ARCH=arch-conda-c-opt
export HYDRA_LAUNCHER=fork

unset CFLAGS CPPFLAGS CXXFLAGS FFLAGS LIBS
if [[ $(uname) == Darwin ]]; then
    export LDFLAGS="${LDFLAGS:-} -Wl,-headerpad_max_install_names"
    ADDITIONAL_ARGS="--with-blas-lib=libblas${SHLIB_EXT} --with-lapack-lib=liblapack${SHLIB_EXT}"
else
    ADDITIONAL_ARGS="--download-fblaslapack=1"
fi

if [[ $(uname) == Darwin ]]; then
    TUNING="-march=core2 -mtune=haswell"
else
    TUNING="-march=nocona -mtune=haswell"
fi

# for MPI discovery
export C_INCLUDE_PATH=$PREFIX/include
export CPLUS_INCLUDE_PATH=$PREFIX/include
export FPATH_INCLUDE_PATH=$PREFIX/include

BUILD_CONFIG=`cat <<"EOF"
  --COPTFLAGS=-O3 \
  --CXXOPTFLAGS=-O3 \
  --FOPTFLAGS=-O3 \
  --with-x=0 \
  --with-mpi=1 \
  --with-ssl=0 \
  --with-openmp=1 \
  --with-debugging=0 \
  --with-cxx-dialect=C++11 \
  --with-shared-libraries=1 \
  --download-mumps=1 \
  --download-hypre=1 \
  --download-metis=1 \
  --download-slepc=1 \
  --download-ptscotch=1 \
  --download-parmetis=1 \
  --download-scalapack=1 \
  --download-superlu_dist=1 \
  --with-fortran-bindings=0 \
  --with-sowing=0 \
EOF
`

python ./configure ${BUILD_CONFIG} ${ADDITIONAL_ARGS:-} \
       AR="${AR:-ar}" \
       CC="mpicc" \
       CXX="mpicxx" \
       FC="mpifort" \
       F90="mpifort" \
       F77="mpifort" \
       CFLAGS="${TUNING}" \
       CXXFLAGS="${TUNING}" \
       LDFLAGS="${LDFLAGS:-}" \
       --prefix=${INSTALL_DIR}/petsc || (cat configure.log && exit 1)

# Verify that gcc_ext isn't linked
for f in $PETSC_ARCH/lib/petsc/conf/petscvariables $PETSC_ARCH/lib/pkgconfig/PETSc.pc; do
  if grep gcc_ext $f; then
    echo "gcc_ext found in $f"
    exit 1
  fi
done

sedinplace() {
  if [[ $(uname) == Darwin ]]; then
    sed -i "" "$@"
  else
    sed -i"" "$@"
  fi
}

# Remove abspath of ${BUILD_PREFIX}/bin/python
sedinplace "s%${BUILD_PREFIX}/bin/python%python%g" $PETSC_ARCH/include/petscconf.h
sedinplace "s%${BUILD_PREFIX}/bin/python%python%g" $PETSC_ARCH/lib/petsc/conf/petscvariables
sedinplace "s%${BUILD_PREFIX}/bin/python%/usr/bin/env python%g" $PETSC_ARCH/lib/petsc/conf/reconfigure-arch-conda-c-opt.py

# Replace abspath of ${PETSC_DIR} and ${BUILD_PREFIX} with ${PREFIX}
for path in $PETSC_DIR $BUILD_PREFIX; do
    for f in $(grep -l "${path}" $PETSC_ARCH/include/petsc*.h); do
        echo "Fixing ${path} in $f"
        sedinplace s%$path%\${INSTALL_DIR}/petsc%g $f
    done
done

make

# FIXME: Workaround mpiexec setting O_NONBLOCK in std{in|out|err}
# See https://github.com/conda-forge/conda-smithy/pull/337
# See https://github.com/pmodels/mpich/pull/2755
make check MPIEXEC="${RECIPE_DIR}/mpiexec.sh"

make install

# Remove unneeded files
rm -f ${INSTALL_DIR}/petsc/lib/petsc/conf/configure-hash
find ${INSTALL_DIR}/petsc/lib/petsc -name '*.pyc' -delete

# Replace ${BUILD_PREFIX} after installation,
# otherwise 'make install' above may fail
for f in $(grep -l "${BUILD_PREFIX}" -R "${INSTALL_DIR}/petsc/lib/petsc"); do
  echo "Fixing ${BUILD_PREFIX} in $f"
  sedinplace s%${BUILD_PREFIX}%${INSTALL_DIR}/petsc%g $f
done

echo "Removing example files"
du -hs ${INSTALL_DIR}/petsc/share/petsc/examples/src
rm -fr ${INSTALL_DIR}/petsc/share/petsc/examples/src
echo "Removing data files"
du -hs ${INSTALL_DIR}/petsc/share/petsc/datafiles/*
rm -fr ${INSTALL_DIR}/petsc/share/petsc/datafiles


#### LIBMESH
cd ${O_WORKDIR}/moose/libmesh
export PETSC_DIR=${INSTALL_DIR}/petsc
export PKG_CONFIG_PATH=$BUILD_PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH

if [ -z $PETSC_DIR ]; then
    printf "PETSC not found.\n"
    exit 1
fi

function sed_replace(){
    if [ `uname` = "Darwin" ]; then
        sed -i '' -e "s|${BUILD_PREFIX}|${INSTALL_DIR}/libmesh|g" ${INSTALL_DIR}/libmesh/bin/libmesh-config
    else
        sed -i'' -e "s|${BUILD_PREFIX}|${INSTALL_DIR}/libmesh|g" ${INSTALL_DIR}/libmesh/bin/libmesh-config
    fi
}

mkdir -p build; cd build

if [[ $(uname) == Darwin ]]; then
    TUNING="-march=core2 -mtune=haswell"
else
    TUNING="-march=nocona -mtune=haswell"
fi

unset LIBMESH_DIR CFLAGS CPPFLAGS CXXFLAGS FFLAGS LIBS \
      LDFLAGS DEBUG_CPPFLAGS DEBUG_CFLAGS DEBUG_CXXFLAGS \
      FORTRANFLAGS DEBUG_FFLAGS DEBUG_FORTRANFLAGS
export F90=mpifort
export F77=mpifort
export FC=mpifort
export CC=mpicc
export CXX=mpicxx
export CFLAGS="${TUNING}"
export CXXFLAGS="${TUNING}"
export LDFLAGS="-Wl,-S"
export HYDRA_LAUNCHER=fork
export VTKLIB_DIR=${PREFIX}/libmesh-vtk/lib
export VTKINCLUDE_DIR=${PREFIX}/libmesh-vtk/include/vtk-${SHORT_VTK_NAME}

BUILD_CONFIG=`cat <<EOF
--enable-silent-rules \
--enable-unique-id \
--disable-warnings \
--enable-glibcxx-debugging \
--with-thread-model=openmp \
--disable-maintainer-mode \
--enable-petsc-hypre-required \
--enable-metaphysicl-required
EOF`

../configure ${BUILD_CONFIG} \
                     --prefix=${INSTALL_DIR}/libmesh \
                     --with-vtk-lib=${VTKLIB_DIR} \
                     --with-vtk-include=${VTKINCLUDE_DIR} \
                     --with-methods="opt" \
                     --without-gdb-command

make -j $CPU_COUNT
make install
sed_replace

#### PIKA
cd ${O_WORKDIR}/moose
git apply ../conda/no_verify_conda.patch
export EXTERNAL_FLAGS="-Wl,-headerpad_max_install_names"
export LIBMESH_DIR=${INSTALL_DIR}/libmesh
./configure --prefix=${INSTALL_DIR}
cd ${O_WORKDIR}
make -j $CPU_COUNT
make install
cd ${PREFIX}/bin
ln -s ${INSTALL_DIR}/bin/pika-opt .
