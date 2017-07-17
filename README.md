# Mesa Coverage

Instructions on how to obtain code coverage of Mesa.

## Mesa vocabulary

A link to explain Mesa-related vocabulary:

https://www.reddit.com/r/archlinux/comments/6la6n5/trying_to_understand_drm_dri_mesa_radeon_gallium/

## Build a new version

Clone this repo, create a relevant configuration file, and run the
`new_version.sh` script:

```sh
$ cp configuration.sh.template configuration.sh
$ ## TODO: edit configuration.sh
$ ./new_version.sh
```

This should create a `mesa-<version>_cov.tar` and
`mesa-<version>_cov_src` folder.

For the compilation flow details, see the `new_version.sh` script internals.

# Hugues's old raw notes:

# Libdrm drm

Obtained from:

    git clone git://anongit.freedesktop.org/mesa/drm

Configure:

    ./autogen.sh --prefix=/data/MesaBuild/install

Build:

    make -j 7
    make install

# LLVM

See http://llvm.org/docs/CMake.html

Obtained from:

    svn co http://llvm.org/svn/llvm-project/llvm/trunk llvm

Configure: we only want to produce a shared library with GPU-related
targets.

    cd llvm/build/
    cmake -G "Ninja" \
        -DCMAKE_BUILD_TYPE="Release" \
        -DCMAKE_INSTALL_PREFIX="/data/MesaBuild/install" \
        -DLLVM_TARGETS_TO_BUILD="AMDGPU;NVPTX" \
        -DLLVM_BUILD_TOOLS="OFF" \
        -DLLVM_BUILD_EXAMPLES="OFF" \
        -DLLVM_BUILD_TESTS="OFF" \
        -DLLVM_BUILD_DOCS="OFF" \
        -DLLVM_BUILD_LLVM_DYLIB="ON" \
        ../

Then:

    cd llvm/build/
    ninja
    ninja install

    # Watch out, we also need llvm-config
    ninja llvm-config
    # ninja install does not seem to install llvm-config, maybe
    # due to disabling building of tools in cmake command
    cp bin/llvm-config /data/MesaBuild/install/bin/

# Mesa

Obtained from:

    git://anongit.freedesktop.org/git/mesa/mesa

Generate configure script, one-time action:

    ./autogen.sh

Configure:

    # This first line is needed to find the relevant libdrm
    PKG_CONFIG_PATH=/data/MesaBuild/install/lib/pkgconfig \
        ./configure \
        --with-llvm-prefix="/data/LLVM-4.0.0/install" \
        --enable-llvm \
        --prefix="/data/MesaBuild/install" \
        --disable-vdpau \
        --disable-va \
        --disable-xvmc \
        --with-dri-drivers=i965 \
        --with-gallium-drivers=radeonsi \
        --with-egl-platforms=x11,drm \
        --enable-texture-float \
        --enable-debug \
        --enable-profile \
        --enable-gbm \
        --enable-glx-tls

Build

    make -j 8
    make install

# Wrap all we need into a package

Now all we need is under /data/MesaBuild/install , but there is way too
much there. We can extract only what we need into a package. We name the
package after the build date and latest mesa commit. Also, we register
which version of each library were used for this build.

    DATE=`date '+%Y-%m-%d'`
    MESAVERSION=`( cd mesa ; git log --oneline -n 1 | awk '{ print $1 }')`
    DEST="mesa_${DATE}_${MESAVERSION}"
    mkdir $DEST
    echo "Mesa: $MESAVERSION" > $DEST/VERSIONS
    ( echo -n "LLVM: " ; cd llvm ; svn info | grep "Revision") >> $DEST/VERSIONS
    ( echo -n "DRM: " ; cd drm ; git log --oneline -n 1 | awk '{ print $1 }') >> $DEST/VERSIONS
    cp -d install/lib/*.so* $DEST/
    cp -d install/lib/dri/*.so $DEST/
    tar cvf ${DEST}.tar $DEST

# How to use the package

Source a script that refer to the package:

    MESADIR="$HOME/mesa_2017-01-01_123abc"
    LD_LIBRARY_PATH="$MESADIR"
    export LD_LIBRARY_PATH
    LIBGL_DRIVERS_PATH="$MESADIR"
    export LIBGL_DRIVERS_PATH

# Coverage

When configuring Mesa, set the following environment variables:

    CFLAGS="--coverage"
    export CFLAGS
    CXXFLAGS="--coverage"
    export CXXFLAGS
    LIBS="-lgcov"
    export LIBS

Then rebuild mesa: make clean, make, etc

When using this coverage-enabled version of Mesa, the executable will create
coverage info files. You need to set the following to control this:

    export GCOV_PREFIX_STRIP=4
    export GCOV_PREFIX=$HOME/coverage

Then move back the files, see:
http://bobah.net/d4d/tools/code-coverage-with-gcov

# TODO

 - work on profiling

# New version

File structure:

```
/mesa/    mesa sources
/llvm/    link to LLVM/install directory
/install  local install, with libdrm installed there
```
