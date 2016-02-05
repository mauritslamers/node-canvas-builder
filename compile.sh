#!/bin/bash

set -e

if [[ $TRAVIS_OS_NAME == "linux" ]]; then
  LDFLAGS="-Wl,-R,'\$\$ORIGIN'"

  # first create out
  mkdir -p out
  OUTDIR=`pwd`/out

  cd build

  PKG_CONFIG_PATH=$OUTDIR/lib/pkgconfig

  #LIBFREETYPE
  cd freetype-$VERSIONLIBFREETYPE
  PKG_CONFIG_PATH=$PKG_CONFIG_PATH ./configure --prefix=$OUTDIR > /dev/null
  make install > /dev/null
  cd ..

  #FONTCONFIG
  cd fontconfig-$VERSIONLIBFONTCONFIG
  PKG_CONFIG_PATH=$PKG_CONFIG_PATH ./configure --prefix=$OUTDIR --disable-dependency-tracking > /dev/null
  make LDFLAGS=$LDFLAGS > /dev/null
  make install > /dev/null
  cd ..

  #LIBJPEG
  cd jpeg-$VERSIONLIBJPEG
  PKG_CONFIG_PATH=$PKG_CONFIG_PATH ./configure --prefix=$OUTDIR --disable-dependency-tracking > /dev/null
  make install > /dev/null
  cd ..

  #LIBPNG
  cd libpng-$VERSIONLIBPNG
  PKG_CONFIG_PATH=$PKG_CONFIG_PATH ./configure --prefix=$OUTDIR --disable-dependency-tracking > /dev/null
  make install > /dev/null
  cd ..

  #GIFLIB
  cd giflib-$VERSIONGIFLIB
  PKG_CONFIG_PATH=$PKG_CONFIG_PATH ./configure --prefix=$OUTDIR --disable-dependency-tracking > /dev/null
  make install > /dev/null
  cd ..

  #PIXMAN
  echo compiling pixman
  cd pixman-$VERSIONPIXMAN
  PKG_CONFIG_PATH=$PKG_CONFIG_PATH ./configure --prefix=$OUTDIR --disable-dependency-tracking > /dev/null
  cat config.log
  make install > /dev/null
  cd ..

  #CAIRO
  cd cairo-$VERSIONCAIRO
  if [[ $TRAVIS_OS_NAME == "osx" ]]; then
    PKG_CONFIG_PATH=$PKG_CONFIG_PATH ./configure --prefix=$OUTDIR --disable-dependency-tracking --disable-xlib --disable-xlib-xrender --disable-xcb --disable-xlib-xcb --disable-xcb-shm > /dev/null
  else
    PKG_CONFIG_PATH=$PKG_CONFIG_PATH ./configure --prefix=$OUTDIR --with-x --disable-dependency-tracking --disable-full-testing --disable-lto > /dev/null
  fi
  make > /dev/null
  make install > /dev/null
  cd ..

  cd ..
fi

#NODE_CANVAS

cd node-canvas
#now we need to do some editing in order to make the build products named correctly
# mv src/init.cc src/initcc.old
# sed s/NODE_MODULE\(canvas,init\)/NODE_MODULE\(canvas_$TRAVIS_OS_NAME\_$ARCH,init\)/ < src/initcc.old  > src/init.cc
# chmod 755 src/init.cc
mv binding.gyp bindinggyp.old
node -v #log node version to be sure...
if [[ $TRAVIS_OS_NAME == "linux" ]]; then
  # the line below does two things: rename the build product and forces pangocairo to false, as cairo doesn't provide pangocairo.pc (somehow)
  cat bindinggyp.old | sed -r "s/('with_pango.+)('.+pangocairo\)')/\1 'false'/" > binding.gyp
  #LDFLAGS="-Wl,-R,'\$\$ORIGIN/../../binlibs'" PKG_CONFIG_PATH=$PKG_CONFIG_PATH node-gyp rebuild
  LDFLAGS=$LDFLAGS PKG_CONFIG_PATH=$PKG_CONFIG_PATH npm install || exit 1
else
  #sed s/canvas/canvas_osx/ < bindinggyp.old > binding.gyp
  npm install
fi
cd ..


