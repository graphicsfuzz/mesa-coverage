#!/bin/sh

MESA_VERSION="mesa-17.1.4"
DRM_VERSION="libdrm-2.4.81"
LLVM_PATH="/vol/multicore/llvm-4.0.0"
INSTALL_DIR="/data/MesaBuild/install"

cat <<EOF
********************************************************************
MESA_VERSION: $MESA_VERSION
DRM_VERSION: $DRM_VERSION
LLVM_PATH (from mesa dir): $LLVM_PATH
INSTALL_DIR: $INSTALL_DIR

You can update these by editing the script ($0)
********************************************************************
EOF

echo -n "Is this OK? [y/n] "
read answer

if test $answer != "y"
then
    echo "Abort"
    exit 1
fi

set -e

# drm

# Only update when a new version is announced. Check drm mailing list
# for announcement, and checkout the corresponding git tag.

# https://lists.freedesktop.org/archives/dri-devel/

# To checkout a version: git pull ; git checkout libdrm-2.4.81

(
    set -e
    cd drm

    if test -f LATEST_BUILD -a `cat LATEST_BUILD` = $DRM_VERSION
    then
        echo "libdrm already up-to-date"
    else

        git checkout master
        git pull
        git checkout $DRM_VERSION
        ./autogen.sh --prefix="$INSTALL_DIR"
        make -j 7
        echo "$DRM_VERSION" > LATEST_BUILD
        make install

    fi
)

echo "#########################################################################"
echo "# libdrm updated to version $DRM_VERSION"
echo "#########################################################################"

# llvm

# Must be already compiled and installed somewhere else. LLVM_PATH
# should point to the install directory. Prefer relative path in order
# to make coverage easier.

echo "#########################################################################"
echo "# Using LLVM from path: $LLVM_PATH"
echo "#########################################################################"

# mesa
(
    set -e
    cd mesa

    if test -f LATEST_BUILD -a `cat LATEST_BUILD` = $MESA_VERSION
    then
        echo "mesa already up-to-date"
    else

        git checkout master
        git pull
        git checkout $MESA_VERSION

        make clean

        # config with coverage
        CFLAGS="--coverage" \
              CXXFLAGS="--coverage" \
              LIBS="-lgcov" \
              PKG_CONFIG_PATH=/data/MesaBuild/install/lib/pkgconfig \
              ./configure \
              --with-llvm-prefix="$LLVM_PATH" \
              --enable-llvm \
              --prefix="$INSTALL_DIR" \
              --enable-debug \
              --enable-profile \
              --with-dri-drivers=i965,swrast \
              --with-gallium-drivers=radeonsi \
              --with-vulkan-driver=intel,radeon

        make -j 8
        make install

        echo "$MESA_VERSION" > LATEST_BUILD

    fi
)

echo "#########################################################################"
echo "# mesa updated to version: $MESA_VERSION"
echo "#########################################################################"

# creates reference for coverage

DEST="/vol/multicore/hevrard/mesa/${MESA_VERSION}_cov_src"
if test -d $DEST
then
    echo "$DEST already exists, no update of source and gcno files"
else
    mkdir $DEST
    rsync -avz \
          --filter='+ */' \
          --filter='+ *.c'   --filter='+ *.h' \
          --filter='+ *.cpp' --filter='+ *.hpp' \
          --filter='+ *.y'   --filter='+ *.l' \
          --filter='+ *.yy'  --filter='+ *.ll' \
          --filter='+ *.gcno' \
          --filter='- *' \
          mesa $DEST/

    cp get-coverage-info.sh $DEST/
    chmod ug+x $DEST/get-coverage-info.sh

    cp my_gcov.sh $DEST/
    (
        cd $DEST
        echo "" >>  my_gcov.sh
        find . -name '*.gcno' | sed -e 's+^+call_gcov +' >> my_gcov.sh
    )
    chmod u+x $DEST/my_gcov.sh
fi

echo "#########################################################################"
echo "# Sources for coverage available: $DEST"
echo "#########################################################################"

# Wrap into a package
DEST="${MESA_VERSION}_cov"
rm -rf $DEST
mkdir $DEST
cp -d install/lib/*.so* $DEST/
cp -d install/lib/dri/*.so $DEST/
(
    cd mesa
    cp -d $LLVM_PATH/lib/*LLVM*so ../$DEST
)

cat environ.sh \
    | sed -e 's/@MESA_PACKAGE@/'"$DEST"'/' \
    > $DEST/environ.sh

rm -rf $DEST.tar
tar cvf ${DEST}.tar $DEST

echo "#########################################################################"
echo "# Package created: $DEST.tar"
echo "#########################################################################"
