#!/bin/bash

set -e

OUTDIR=`pwd`/out

mkdir package
# copy in everything from node_canvas_bin
cd package
cp -vr ../node-canvas-bin/* .

#now copy everything library file we need from the build folder
mkdir binlib
cd binlib
if [[ $TRAVIS_OS_NAME == "linux" ]]; then
  cp node-canvas/build/Release/canvas_linux_$ARCH.node ./canvas_linux_$ARCH.node
  for f in libcairo.so.2 libpng16.so.16 libjpeg.so.8 libgif.so.4 libpixman-1.so.0 libfreetype.so.6
  do
    #don't take anything else, and we are interested in the file, not the symlink as it doesn't survive the install by npm
    cp $OUTDIR/lib/$f ./$f
  done
fi

if [[ $TRAVIS_OS_NAME == "osx" ]]; then
  cp $OUTDIR/lib/libpixman-1.0.dylib .
  cp $OUTDIR/lib/libcairo.dylib .
  cp $OUTDIR/lib/libcairo.2.dylib .
  cp $OUTDIR/lib/libfreetype.6.dylib .
  cp $OUTDIR/lib/libpng15.15.dylib .
  cp $OUTDIR/lib/libjpeg.8.dylib .
  cp $OUTDIR/lib/libfontconfig.1.dylib .

  ## Enable absolute loading paths into relative paths
  ##start renaming, pixman first
  install_name_tool -change $OUTDIR/lib/libpixman-1.0.dylib @loader_path/libpixman-1.0.dylib libpixman-1.0.dylib

  #libfontconfig
  install_name_tool -change $OUTDIR/lib/libfreetype.6.dylib @loader_path/libfreetype.6.dylib libfontconfig.dylib

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
fi

cp -rv ../test .
cd test
node test.js
# if this succeeds, we can archive and upload
cd ..

if [[ $TRAVIS_OS_NAME == "linux" ]]; then
  PACKAGENAME=linux_$ARCH\_$NODE_VERSION
else
  PACKAGENAME=osx_$NODE_VERSION
fi
tar -cvzf ../$PACKAGENAME.tar.gz *

export PACKAGEFILENAME=$PACKAGENAME.tar.gz

cd ..


