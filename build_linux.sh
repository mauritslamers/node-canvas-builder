#!/bin/bash

#make every problem an error
set -e

#prerequisites
command -v xz >/dev/null 2>&1 || { echo >&2 "please install xz before continuing. Aborting..."; exit 1; }
command -v pkg-config >/dev/null 2>&1 || { echo >&2 "please install pkg-config before continuing. Aborting..."; exit 1; }

echo "Trying to detect whether you have X11 headers installed. "
if [ -d /usr/include/X11 ]; then
  if [ -f /usr/include/X11/X.h ]; then
    if [ -f /usr/include/X11/extensions/XShm.h ]; then
      echo "X11 detected"
    else
      echo "X11 detected, but it is not complete. Please install a package with XShm.h in it (libxext-dev in Ubuntu)."
      exit 1
    fi
  else
    echo "X11 directory found, but X.h is missing. Please make sure you have the X11 headers installed (libx11-dev and libxext-dev in Ubuntu)."
    exit 1
  fi
else
  if [ command -v locate >/dev/null 2>&1 ]; then
     if [ -e `locate X.h`]; then
       echo "X11 detected"
     else
       echo "You don't have a directory /usr/include/X11 and locate couldn't find a X.h. Aborting..."
       exit 1
     fi
  else
    echo "You don't have a directory /usr/include/X11 and there is no locate command installed."
    echo "If you are running Ubuntu, check whether you have the packages libx11-dev and libxext-dev installed."
    echo "Either adjust this script to properly detect X11, or install the locate command and have it index your system."
    exit 1
  fi
fi

#building instructions for node-canvas
#(for now assume pkg-config exists already) install pkg-config
#install pixman
#install cairo
BUILDPWD=`pwd`
BUILDDIR=$BUILDPWD/build
TMPDIR=$BUILDPWD/tmp
OUTDIR=$BUILDPWD/out
NODEMODULEDIR=$BUILDPWD/node-canvas-bin-libs
NODECANVASBRANCH=master
BUILDPLATFORM=`uname -i`

if [ $BUILDPLATFORM == "i686" ]; 
  then
    BUILDPLATFORM="ia32"
fi

PKG_CONFIG_PATH=$OUTDIR/lib/pkgconfig

#add origin as ldflag so extra libraries can find one another
LDFLAGS="-Wl,-R,'\$ORIGIN'"
echo Compiling with LDFLAGS $LDFLAGS



VERSION_PIXMAN=0.30.0
VERSION_LIBPNGMAIN=16 #for url composing
VERSION_LIBPNG=1.6.16
VERSION_CAIRO=1.12.18
VERSION_FREETYPE=2.4.11
VERSION_FONTCONFIG=2.10.93

mkdir -p tmp
mkdir -p build
mkdir -p out

# echo PWD is $BUILDPWD
echo Downloading and compiling pixman to $TMPDIR/pixman.tar.gz
curl http://www.cairographics.org/releases/pixman-$VERSION_PIXMAN.tar.gz -z $TMPDIR/pixman.tar.gz -o $TMPDIR/pixman.tar.gz
cd $BUILDDIR
tar -xvzf $TMPDIR/pixman.tar.gz && cd $BUILDDIR/pixman-$VERSION_PIXMAN/
echo ./configure --prefix=$BUILDDIR --disable-dependency-tracking
./configure --prefix=$OUTDIR --disable-dependency-tracking
make install
cd $BUILDPWD

echo Downloading and compiling libpng to $TMPDIR/libpng.tar.gz
curl -L http://sourceforge.net/projects/libpng/files/libpng$VERSION_LIBPNGMAIN/$VERSION_LIBPNG/libpng-$VERSION_LIBPNG.tar.gz/download -z $TMPDIR/libpng.tar.gz -o $TMPDIR/libpng.tar.gz
cd $BUILDDIR
tar -xvzf $TMPDIR/libpng.tar.gz && cd $BUILDDIR/libpng-$VERSION_LIBPNG
echo ./configure --prefix=$OUTDIR --disable-dependency-tracking
./configure --prefix=$OUTDIR --disable-dependency-tracking ||  { echo "build_linux: If this error is about zlib, install zlib. Under Ubuntu this is in the package zlib1g-dev."; exit 1; }
make install || exit 1
cd $BUILDDIR

echo Downloading and compiling libfreetype
curl -L http://download.savannah.gnu.org/releases/freetype/freetype-$VERSION_FREETYPE.tar.gz -z $TMPDIR/freetype.tar.gz -o $TMPDIR/freetype.tar.gz
cd $BUILDDIR
tar -xvzf $TMPDIR/freetype.tar.gz
cd $BUILDDIR/freetype-$VERSION_FREETYPE
PKG_CONFIG_PATH=$PKG_CONFIG_PATH ./configure --prefix=$OUTDIR --disable-dependency-tracking || exit 1
make LDFLAGS=$LDFLAGS || exit 1
make install
cd $BUILDDIR

echo Downloading and compiling fontconfig
curl -L http://fontconfig.org/release/fontconfig-$VERSION_FONTCONFIG.tar.gz -z $TMPDIR/fontconfig.tar.gz -o $TMPDIR/fontconfig.tar.gz
cd $BUILDDIR
tar -xvzf $TMPDIR/fontconfig.tar.gz
cd $BUILDDIR/fontconfig-$VERSION_FONTCONFIG
PKG_CONFIG_PATH=$PKG_CONFIG_PATH ./configure --prefix=$OUTDIR --disable-dependency-tracking ||  { echo "If this fails with xmlparse.h and expat messages, install expat, apt-get install libexpat1-dev under Ubuntu."; exit 1; }
make LDFLAGS=$LDFLAGS || { echo $LDFLAGS; exit 1; }
make install
# Sometimes this fails with failing to find the zlib functions inflate* in the freetype lib.
# Unclear why exactly... retrying a few times usually works.
cd $BUILDDIR

echo Downloading and compiling libjpeg to $TMPDIR/jpegsrc.v8.tar.gz
curl -L http://www.ijg.org/files/jpegsrc.v8.tar.gz  -z $TMPDIR/jpegsrc.v8.tar.gz -o $TMPDIR/jpegsrc.v8.tar.gz
cd $BUILDDIR
tar -xvzf $TMPDIR/jpegsrc.v8.tar.gz && cd $BUILDDIR/jpeg-8
echo ./configure --prefix=$OUTDIR --disable-dependency-tracking
PKG_CONFIG_PATH=$PKG_CONFIG_PATH ./configure --prefix=$OUTDIR --disable-dependency-tracking
make install
cd $BUILDDIR

echo Downloading and compiling giflib to $TMPDIR/giflib-4.1.6.tar.gz
curl -L https://downloads.sourceforge.net/project/giflib/giflib-4.x/giflib-4.1.6/giflib-4.1.6.tar.gz  -z $TMPDIR/giflib-4.1.6.tar.gz -o $TMPDIR/giflib-4.1.6.tar.gz
cd $BUILDDIR
tar -xvzf $TMPDIR/giflib-4.1.6.tar.gz && cd $BUILDDIR/giflib-4.1.6
echo ./configure --prefix=$OUTDIR --disable-dependency-tracking
PKG_CONFIG_PATH=$PKG_CONFIG_PATH ./configure --prefix=$OUTDIR --disable-dependency-tracking
make install
cd $BUILDDIR

echo Downloading and compiling cairo
if [ ! -e $TMPDIR/cairo.tar ]
then
  curl http://www.cairographics.org/releases/cairo-$VERSION_CAIRO.tar.xz -z $TMPDIR/cairo.tar -o $TMPDIR/cairo.tar.xz
  xz -d $TMPDIR/cairo.tar.xz
fi
cd $BUILDDIR
tar -xvf $TMPDIR/cairo.tar
cd $BUILDDIR/cairo-$VERSION_CAIRO
echo ./configure --prefix=$OUTDIR --disable-dependency-tracking
PKG_CONFIG_PATH=$PKG_CONFIG_PATH ./configure --prefix=$OUTDIR --with-x --disable-dependency-tracking --disable-full-testing --disable-lto
make 
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
sed s/NODE_MODULE\(canvas,init\)/NODE_MODULE\(canvas_linux_$BUILDPLATFORM,init\)/ < src/initcc.old  > src/init.cc
chmod 755 src/init.cc
mv binding.gyp bindinggyp.old
sed s/canvas/canvas_linux_$BUILDPLATFORM/ < bindinggyp.old > binding.gyp
#LDFLAGS="-Wl,-R,'\$\$ORIGIN/../../binlibs'" PKG_CONFIG_PATH=$PKG_CONFIG_PATH node-gyp rebuild
LDFLAGS=$LDFLAGS PKG_CONFIG_PATH=$PKG_CONFIG_PATH npm install || exit 1

cd $BUILDPWD
## Now we are going to create the node-canvas-bin package
## first check out the current one, then copy the new files over
if [ ! -d $NODEMODULEDIR ]
then
  git clone git@github.com:mauritslamers/node-canvas-bin-libs
  git checkout -f linux-$BUILDPLATFORM
else
  cd $NODEMODULEDIR
  git checkout -f $NODECANVASBRANCH #reset any changes
  cd $BUILDPWD
fi

mkdir -p $NODEMODULEDIR/build/Release
cp node-canvas/build/Release/canvas_linux_$BUILDPLATFORM.node $NODEMODULEDIR/build/Release/canvas_linux_$BUILDPLATFORM.node

mkdir -p $NODEMODULEDIR/binlib

for f in libcairo.so.2 libpng16.so.16 libjpeg.so.8 libgif.so.4 libpixman-1.so.0 libfontconfig.so.1 libfreetype.so.6 
do
  #don't take anything else, and we are interested in the file, not the symlink as it doesn't survive the install by npm
  cp $OUTDIR/lib/$f $NODEMODULEDIR/binlib/linux_$BUILDPLATFORM/$f
done

#Before testing, run the package.json creator
cd $BUILDPWD
node create_packagejson.js

#we temporarily rename the out folder, so any problems will be visible on the test
mv $BUILDPWD/out $BUILDPWD/out_tmp

cd $BUILDPWD
echo Now testing the newly created package
cd test
./test.js
cd ..

#rename back
mv $BUILDPWD/out_tmp $BUILDPWD/out

#done?
echo If you didn\'t see warnings, the package is good to be shipped. Don\'t forget to commit the changes.