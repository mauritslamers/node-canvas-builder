#!/bin/sh

#prerequisites
command -v xz >/dev/null 2>&1 || { echo >&2 "please install xz (homebrew?) before continuing. Aborting..."; exit 1; }

#building instructions for node-canvas
#(for now assume pkg-config exists already) install pkg-config
#install pixman
#install cairo
BUILDPWD=`pwd`
BUILDDIR=$BUILDPWD/build
TMPDIR=$BUILDPWD/tmp
OUTDIR=$BUILDPWD/out
NODEMODULEDIR=$BUILDPWD/node-canvas-bin-libs

PKG_CONFIG_PATH=$OUTDIR/lib/pkgconfig

VERSION_PIXMAN=0.30.0
#VERSION_LIBPNGMAIN=16 #for url composing
#VERSION_LIBPNG=1.6.2
VERSION_LIBPNGMAIN=15
VERSION_LIBPNG=1.5.16
VERSION_CAIRO=1.10.2
VERSION_FREETYPE=2.4.11
VERSION_FONTCONFIG=2.10.93
NODEVERSION=`node -v | sed 's/v\([0-9]*\.[0-9]*\).[0-9]/\1/'`
NODECANVASBRANCH=osx_"$NODEVERSION"

mkdir -p tmp
mkdir -p build
mkdir -p out

echo Downloading and compiling libfreetype
curl -L http://download.savannah.gnu.org/releases/freetype/freetype-$VERSION_FREETYPE.tar.gz -z $TMPDIR/freetype.tar.gz -o $TMPDIR/freetype.tar.gz
cd $BUILDDIR
tar -xvzf $TMPDIR/freetype.tar.gz
cd $BUILDDIR/freetype-$VERSION_FREETYPE
PKG_CONFIG_PATH=$PKG_CONFIG_PATH ./configure --prefix=$OUTDIR --disable-dependency-tracking
make install
cd $BUILDDIR

echo Downloading and compiling fontconfig
curl -L http://fontconfig.org/release/fontconfig-$VERSION_FONTCONFIG.tar.gz -z $TMPDIR/fontconfig.tar.gz -o $TMPDIR/fontconfig.tar.gz
cd $BUILDDIR
if [ -a $BUILDDIR/fontconfig-$VERSION_FONTCONFIG ] #recompile fontconfig by default to prevent fcache to run
then
  rm -r $BUILDDIR/fontconfig-$VERSION_FONTCONFIG
fi
tar -xvzf $TMPDIR/fontconfig.tar.gz
cd $BUILDDIR/fontconfig-$VERSION_FONTCONFIG
PKG_CONFIG_PATH=$PKG_CONFIG_PATH ./configure --prefix=$OUTDIR --disable-dependency-tracking
make install
cd $BUILDDIR

echo Downloading and compiling libjpeg to $TMPDIR/jpegsrc.v8.tar.gz
curl -L http://www.ijg.org/files/jpegsrc.v8.tar.gz  -z $TMPDIR/jpegsrc.v8.tar.gz -o $TMPDIR/jpegsrc.v8.tar.gz
cd $BUILDDIR
tar -xvzf $TMPDIR/jpegsrc.v8.tar.gz && cd $BUILDDIR/jpeg-8
echo ./configure --prefix=$OUTDIR --disable-dependency-tracking
PKG_CONFIG_PATH=$PKG_CONFIG_PATH ./configure --prefix=$OUTDIR --disable-dependency-tracking
make install
cd $BUILDDIR

echo Downloading and compiling libpng to $TMPDIR/libpng.tar.gz
curl -L http://sourceforge.net/projects/libpng/files/libpng$VERSION_LIBPNGMAIN/$VERSION_LIBPNG/libpng-$VERSION_LIBPNG.tar.gz/download -z $TMPDIR/libpng.tar.gz -o $TMPDIR/libpng.tar.gz
cd $BUILDDIR
tar -xvzf $TMPDIR/libpng.tar.gz && cd $BUILDDIR/libpng-$VERSION_LIBPNG
echo ./configure --prefix=$OUTDIR --disable-dependency-tracking
PKG_CONFIG_PATH=$PKG_CONFIG_PATH ./configure --prefix=$OUTDIR --disable-dependency-tracking
make install
cd $BUILDDIR

echo PWD is $BUILDPWD
echo Downloading and compiling pixman to $TMPDIR/pixman.tar.gz
curl http://www.cairographics.org/releases/pixman-$VERSION_PIXMAN.tar.gz -z $TMPDIR/pixman.tar.gz -o $TMPDIR/pixman.tar.gz
cd $BUILDDIR
tar -xvzf $TMPDIR/pixman.tar.gz && cd $BUILDDIR/pixman-$VERSION_PIXMAN/
echo ./configure --prefix=$BUILDDIR --disable-dependency-tracking
PKG_CONFIG_PATH=$PKG_CONFIG_PATH ./configure --prefix=$OUTDIR --disable-dependency-tracking
make install
cd $BUILDPWD

echo Downloading and compiling cairo
if [ ! -a $TMPDIR/cairo.tar ]
then
  #curl http://www.cairographics.org/releases/cairo-$VERSION_CAIRO.tar.xz -z $TMPDIR/cairo.tar.xz -o $TMPDIR/cairo.tar.xz
  #xz -d $TMPDIR/cairo.tar.xz
  curl http://www.cairographics.org/releases/cairo-$VERSION_CAIRO.tar.gz -z $TMPDIR/cairo.tar.gz -o $TMPDIR/cairo.tar.gz

fi
cd $BUILDDIR
#tar -xvf $TMPDIR/cairo.tar
tar -xvzf $TMPDIR/cairo.tar.gz
cd $BUILDDIR/cairo-$VERSION_CAIRO
echo ./configure --prefix=$OUTDIR --disable-dependency-tracking --disable-xlib --disable-xlib-xrender --disable-xcb --disable-xlib-xcb --disable-xcb-shm
PKG_CONFIG_PATH=$PKG_CONFIG_PATH ./configure --prefix=$OUTDIR --disable-dependency-tracking --disable-xlib --disable-xlib-xrender --disable-xcb --disable-xlib-xcb --disable-xcb-shm
make install
cd $BUILDDIR


## because from node v0.10 it isn't allowed to rename a module _after_ the fact
## doing a simple npm install is not good enough anymore,

#PKG_CONFIG_PATH=$PKG_CONFIG_PATH npm install canvas

if [ ! -d $BUILDPWD/node-canvas ]
then
  git clone git://github.com/LearnBoost/node-canvas
else
  cd $BUILDPWD/node-canvas
  git checkout -f master
  if [ -a ./src/initcc.old ]
  then
    rm ./src/initcc.old
  fi
  if [ -a ./bindinggyp.old ]
  then
    rm ./bindinggyp.old
  fi
  cd ..
fi

cd $BUILDPWD/node-canvas
if [ -a ./src/initcc.old ]
then
  rm ./src/initcc.old
fi
mv src/init.cc src/initcc.old
sed s/NODE_MODULE\(canvas,init\)/NODE_MODULE\(canvas_osx,init\)/ < src/initcc.old  > src/init.cc
chmod 755 src/init.cc
if [ -a ./bindinggyp.old ]
then
  rm bindinggyp.old
fi
mv binding.gyp bindinggyp.old
sed s/canvas/canvas_osx/ < bindinggyp.old > binding.gyp
PKG_CONFIG_PATH=$PKG_CONFIG_PATH node-gyp rebuild

cd $BUILDPWD
## Now we are going to create the node-canvas-bin package
## first check out the current one, then copy the new files over
if [ ! -d $NODEMODULEDIR ]
then
  git clone git@github.com:mauritslamers/node-canvas-bin-libs
fi

cd $NODEMODULEDIR
if [ ! `git checkout -f $NODECANVASBRANCH` ]
  then
    # do a check whether we are actually already in the correct branch, which can happen when a new branch is created.
    if [[ `git status -b --porcelain` != *$NODECANVASBRANCH* ]]
      then
        echo The branch you are trying to check out \($NODECANVASBRANCH\) doesn\'t exist yet.
        echo Create it first by going into the node-canvas-bin-libs directry and execute git checkout --orphan $NODECANVASBRANCH.
        echo Then remove all the content using git rm -rf.
        exit 1;
    fi
    #else, we are in the correct branch, just continue
fi

# we copy carefully
cd $BUILDPWD
#cp -r node-canvas/lib/* $NODEMODULEDIR/lib
mkdir -p $NODEMODULEDIR/binlib
cp $BUILDPWD/node-canvas/build/Release/canvas_osx.node $NODEMODULEDIR/binlib/canvas_osx.node

#cd $NODEMODULEDIR
## but we don't want to overwrite the bindings file
#git checkout $NODEMODULEDIR/lib/bindings.js

#mkdir -p $NODEMODULEDIR/binlib
cd $NODEMODULEDIR/binlib

cp $OUTDIR/lib/libpixman-1.0.dylib $NODEMODULEDIR/binlib
cp $OUTDIR/lib/libcairo.dylib $NODEMODULEDIR/binlib
cp $OUTDIR/lib/libcairo.2.dylib $NODEMODULEDIR/binlib
cp $OUTDIR/lib/libfreetype.6.dylib $NODEMODULEDIR/binlib
cp $OUTDIR/lib/libpng15.15.dylib $NODEMODULEDIR/binlib
cp $OUTDIR/lib/libjpeg.8.dylib $NODEMODULEDIR/binlib
cp $OUTDIR/lib/libfontconfig.1.dylib $NODEMODULEDIR/binlib

##start renaming, pixman first
install_name_tool -change $OUTDIR/lib/libpixman-1.0.dylib @loader_path/libpixman-1.0.dylib libpixman-1.0.dylib

#libfontconfig
install_name_tool -change $OUTDIR/lib/libfreetype.6.dylib @loader_path/libfreetype.6.dylib libfontconfig.dylib
#install_name_tool -change $OUTDIR/lib/libfreetype.6.dylib @loader_path/libfreetype.6.dylib libfontconfig.1.dylib

##cairo
install_name_tool -change $OUTDIR/lib/libcairo.2.dylib @loader_path/libcairo.2.dylib libcairo.dylib
install_name_tool -change $OUTDIR/lib/libpixman-1.0.dylib @loader_path/libpixman-1.0.dylib libcairo.dylib
install_name_tool -change $OUTDIR/lib/libfreetype.6.dylib @loader_path/libfreetype.6.dylib libcairo.dylib
install_name_tool -change $OUTDIR/lib/libpng15.15.dylib @loader_path/libpng15.15.dylib libcairo.dylib
install_name_tool -change $OUTDIR/lib/libfontconfig.1.dylib @loader_path/libfontconfig.1.dylib libcairo.dylib

install_name_tool -change $OUTDIR/lib/libcairo.2.dylib @loader_path/libcairo.2.dylib libcairo.2.dylib
install_name_tool -change $OUTDIR/lib/libpixman-1.0.dylib @loader_path/libpixman-1.0.dylib libcairo.2.dylib
install_name_tool -change $OUTDIR/lib/libfreetype.6.dylib @loader_path/libfreetype.6.dylib libcairo.2.dylib
install_name_tool -change $OUTDIR/lib/libpng15.15.dylib @loader_path/libpng15.15.dylib libcairo.2.dylib
install_name_tool -change $OUTDIR/lib/libfontconfig.1.dylib @loader_path/libfontconfig.1.dylib libcairo.2.dylib

#canvas.node
install_name_tool -change $OUTDIR/lib/libpixman-1.0.dylib @loader_path/libpixman-1.0.dylib canvas_osx.node
install_name_tool -change $OUTDIR/lib/libcairo.2.dylib @loader_path/libcairo.2.dylib canvas_osx.node
install_name_tool -change $OUTDIR/lib/libjpeg.8.dylib @loader_path/libjpeg.8.dylib canvas_osx.node

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
