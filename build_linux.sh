#!/bin/bash

#prerequisites
command -v xz >/dev/null 2>&1 || { echo >&2 "please install xz before continuing. Aborting..."; exit 1; }

#building instructions for node-canvas
#(for now assume pkg-config exists already) install pkg-config
#install pixman
#install cairo
BUILDPWD=`pwd`
BUILDDIR=$BUILDPWD/build
TMPDIR=$BUILDPWD/tmp
OUTDIR=$BUILDPWD/out
NODEMODULEDIR=$BUILDPWD/node-canvas-bin
NODECANVASBRANCH=master

PKG_CONFIG_PATH=$OUTDIR/lib/pkgconfig

#add origin as ldflag so extra libraries can find one another
LDFLAGS="-Wl,-R,'\$ORIGIN'"

VERSION_PIXMAN=0.30.0
VERSION_LIBPNGMAIN=16 #for url composing
VERSION_LIBPNG=1.6.2
VERSION_CAIRO=1.12.14
VERSION_FREETYPE=2.4.11
VERSION_FONTCONFIG=2.10.93

mkdir -p tmp
mkdir -p build
mkdir -p out

# echo PWD is $BUILDPWD
# echo Downloading and compiling pixman to $TMPDIR/pixman.tar.gz
# curl http://www.cairographics.org/releases/pixman-$VERSION_PIXMAN.tar.gz -z $TMPDIR/pixman.tar.gz -o $TMPDIR/pixman.tar.gz
# cd $BUILDDIR
# tar -xvzf $TMPDIR/pixman.tar.gz && cd $BUILDDIR/pixman-$VERSION_PIXMAN/
# echo ./configure --prefix=$BUILDDIR --disable-dependency-tracking
# ./configure --prefix=$OUTDIR --disable-dependency-tracking
# make install 
# cd $BUILDPWD
# 
# echo Downloading and compiling libpng to $TMPDIR/libpng.tar.gz
# curl -L http://sourceforge.net/projects/libpng/files/libpng$VERSION_LIBPNGMAIN/$VERSION_LIBPNG/libpng-$VERSION_LIBPNG.tar.gz/download -z $TMPDIR/libpng.tar.gz -o $TMPDIR/libpng.tar.gz
# cd $BUILDDIR
# tar -xvzf $TMPDIR/libpng.tar.gz && cd $BUILDDIR/libpng-$VERSION_LIBPNG
# echo ./configure --prefix=$OUTDIR --disable-dependency-tracking
# ./configure --prefix=$OUTDIR --disable-dependency-tracking
# make install
# cd $BUILDDIR
# 
# echo Downloading and compiling libfreetype
# curl -L http://download.savannah.gnu.org/releases/freetype/freetype-$VERSION_FREETYPE.tar.gz -z $TMPDIR/freetype.tar.gz -o $TMPDIR/freetype.tar.gz
# cd $BUILDDIR
# tar -xvzf $TMPDIR/freetype.tar.gz
# cd $BUILDDIR/freetype-$VERSION_FREETYPE
# PKG_CONFIG_PATH=$PKG_CONFIG_PATH ./configure --prefix=$OUTDIR --disable-dependency-tracking
# make LDFLAGS=$LDFLAGS
# make install
# cd $BUILDDIR
# 
# echo Downloading and compiling fontconfig
# curl -L http://fontconfig.org/release/fontconfig-$VERSION_FONTCONFIG.tar.gz -z $TMPDIR/fontconfig.tar.gz -o $TMPDIR/fontconfig.tar.gz
# cd $BUILDDIR
# tar -xvzf $TMPDIR/fontconfig.tar.gz
# cd $BUILDDIR/fontconfig-$VERSION_FONTCONFIG
# PKG_CONFIG_PATH=$PKG_CONFIG_PATH ./configure --prefix=$OUTDIR --disable-dependency-tracking
# make LDFLAGS=$LDFLAGS
# make install
# cd $BUILDDIR

echo Downloading and compiling cairo
if [ ! -a $TMPDIR/cairo.tar ] 
then
  curl http://www.cairographics.org/releases/cairo-$VERSION_CAIRO.tar.xz -z $TMPDIR/cairo.tar.xz -o $TMPDIR/cairo.tar.xz
  xz -d $TMPDIR/cairo.tar.xz
fi
cd $BUILDDIR
tar -xvf $TMPDIR/cairo.tar 
cd $BUILDDIR/cairo-$VERSION_CAIRO
echo ./configure --prefix=$OUTDIR --disable-dependency-tracking
PKG_CONFIG_PATH=$PKG_CONFIG_PATH ./configure --prefix=$OUTDIR --disable-dependency-tracking
make LDFLAGS=$LDFLAGS
make install
cd $BUILDPWD
 

#LDFLAGS="-Wl,-R,'\$\$ORIGIN/../../binlibs'" PKG_CONFIG_PATH=$PKG_CONFIG_PATH npm install canvas

## we copy carefully## because node v0.10 doesn't allow module renaming _after_ the fact
## doing a simple npm install is not good enough anymore,
## we have to change the source code to get the right module file and name :##@$#$%#$%#$
echo now in `pwd`
if [ ! -d $BUILDPWD/node-canvas ] 
then
  git clone git://github.com/LearnBoost/node-canvas  
else 
  cd node-canvas
  git checkout -f master
  cd ..
fi

cd node-canvas
mv src/init.cc src/initcc.old
sed s/NODE_MODULE\(canvas,init\)/NODE_MODULE\(canvas_linux,init\)/ < src/initcc.old  > src/init.cc
chmod 755 src/init.cc
mv binding.gyp bindinggyp.old
sed s/canvas/canvas_linux/ < bindinggyp.old > binding.gyp
#LDFLAGS="-Wl,-R,'\$\$ORIGIN/../../binlibs'" PKG_CONFIG_PATH=$PKG_CONFIG_PATH node-gyp rebuild
LDFLAGS="-Wl,-R,'\$\$ORIGIN:\$\$ORIGIN/../../binlibs'" PKG_CONFIG_PATH=$PKG_CONFIG_PATH npm install

cd $BUILDPWD
## Now we are going to create the node-canvas-bin package
## first check out the current one, then copy the new files over
if [ ! -d $NODEMODULEDIR ]
then
  git clone git@github.com:mauritslamers/node-canvas-bin
else 
  cd $NODEMODULEDIR
  git checkout -f $NODECANVASBRANCH #reset any changes
  cd $BUILDPWD
fi

mkdir -p $NODEMODULEDIR/build/Release
cp node-canvas/build/Release/canvas_linux.node $NODEMODULEDIR/build/Release/canvas_linux.node

cp $OUTDIR/lib/libpng16.so.16.2.0 $NODEMODULEDIR/binlibs/libpng16.so.16.2.0


# cp -r node_modules/canvas/lib/* $NODEMODULEDIR/lib
# mkdir -p $NODEMODULEDIR/build/Release
# cp node_modules/canvas/build/Release/canvas.node $NODEMODULEDIR/build/Release/canvas.linux.node

# cd $NODEMODULEDIR
# ## but we don't want to overwrite the bindings file
# git checkout $NODEMODULEDIR/lib/bindings.js
# 
# mkdir -p $NODEMODULEDIR/binlibs
# cd $NODEMODULEDIR/binlibs
# 
# cp $OUTDIR/lib/libpixman-1.* $NODEMODULEDIR/binlibs
# cp $OUTDIR/lib/libcairo.* $NODEMODULEDIR/binlibs
# cp $OUTDIR/lib/libfreetype.* $NODEMODULEDIR/binlibs
# cp $OUTDIR/lib/libpng16.* $NODEMODULEDIR/binlibs
# 
# ##start renaming, pixman first
# install_name_tool -change $OUTDIR/lib/libpixman-1.0.dylib ./binlibs/libpixman-1.0.dylib libpixman-1.0.dylib
# 
# ##cairo
# install_name_tool -change $OUTDIR/lib/libcairo.2.dylib @loader_path/libcairo.2.dylib libcairo.dylib
# install_name_tool -change $OUTDIR/lib/libpixman-1.0.dylib @loader_path/libpixman-1.0.dylib libcairo.dylib
# install_name_tool -change $OUTDIR/lib/libfreetype.6.dylib @loader_path/libfreetype.6.dylib libcairo.dylib
# install_name_tool -change $OUTDIR/lib/libpng16.16.dylib @loader_path/libpng16.16.dylib libcairo.dylib
# 
# install_name_tool -change $OUTDIR/lib/libcairo.2.dylib @loader_path/libcairo.2.dylib libcairo.2.dylib
# install_name_tool -change $OUTDIR/lib/libpixman-1.0.dylib @loader_path/libpixman-1.0.dylib libcairo.2.dylib
# install_name_tool -change $OUTDIR/lib/libfreetype.6.dylib @loader_path/libfreetype.6.dylib libcairo.2.dylib
# install_name_tool -change $OUTDIR/lib/libpng16.16.dylib @loader_path/libpng16.16.dylib libcairo.2.dylib
# 
# cd ..
# 
# #canvas.node
# install_name_tool -change $OUTDIR/lib/libpixman-1.0.dylib @loader_path/../../binlibs/libpixman-1.0.dylib build/Release/canvas.osx.node
# install_name_tool -change $OUTDIR/lib/libcairo.2.dylib @loader_path/../../binlibs/libcairo.2.dylib build/Release/canvas.osx.node

#done?
#echo Done copying and installing relative paths. Don\'t forget to commit the changes.