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
  cp ../../node-canvas/build/Release/canvas_linux_$ARCH.node ./canvas_linux_$ARCH.node
  for f in libcairo.so.2 libpng15.so.15 libjpeg.so.8 libgif.so.4 libpixman-1.so.0 libfreetype.so.6
  do
    #don't take anything else, and we are interested in the file, not the symlink as it doesn't survive the install by npm
    cp $OUTDIR/lib/$f ./$f
  done
fi

if [[ $TRAVIS_OS_NAME == "osx" ]]; then
  # cp $OUTDIR/lib/libpixman-1.0.dylib .
  # cp $OUTDIR/lib/libcairo.dylib .
  # cp $OUTDIR/lib/libcairo.2.dylib .
  # cp $OUTDIR/lib/libfreetype.6.dylib .
  # cp $OUTDIR/lib/libpng15.15.dylib .
  # cp $OUTDIR/lib/libjpeg.8.dylib .
  # cp $OUTDIR/lib/libfontconfig.1.dylib .

  cp -v ../../node-canvas/build/Release/canvas_osx.node ./canvas_osx.node
  chmod +w ./canvas_osx.node #make sure it is writable

  for f in pixman cairo freetype libpng jpeg fontconfig giflib
  do
    for lib in `brew list $f | grep dylib`
    do
      LIST=("${LIST[@]}" $lib)
      #LIST[$LISTCOUNT]=$lib
      cp -v $lib .
      # BNAME=`basename $lib`
      # chmod +w ./$BNAME
      # install_name_tool -change $lib @loader_path/$BNAME $BNAME
      # install_name_tool -change $lib @loader_path/$BNAME canvas_osx
      # chmod -w
    done
  done


  #for debugging purposes
  ls -al
  chmod +w ./*

  #we need to traverse all the file names in the file itself, in order to know the paths
  # first we need all the base names in the current folder
  BASENAMES=`basename *`

  # now we work through every file, and replace all the urls which match a local file
  # with a @loader_path relative reference
  for f in $BASENAMES
  do
    LIBNAMES=`for lib in \`otool -L $f | grep dylib\`; do echo $lib; done | grep dylib`
    for lib in $LIBNAMES
    do
      for file in $BASENAMES
      do
        if [ `basename $lib` == $file ]; then
          #echo in file $f we found library $lib, which corresponds to $file
          install_name_tool -change $lib @loader_path/$file $f
        fi
      done
    done
  done

  #for f in `otool -L canvas_osx.node | grep dylib`; do echo $f; done | grep dylib

  # #now we have all file names in the array, we now can rename everything for every library
  # for lib in ${LIST[@]}
  # do
  #   for f in ${LIST[@]}
  #   do
  #     BNAME=`basename $f`
  #     install_name_tool -change $f @loader_path/$BNAME `basename $lib`
  #   done
  # done

  # # we also need to do this for the node loadable lib
  # for lib in ${LIST[@]}
  # do
  #   BNAME=`basename $lib`
  #   install_name_tool -change $lib @loader_path/$BNAME canvas_osx.node
  # done

  # make readonly again
  chmod -w ./*
  ls -al

  # ## Enable absolute loading paths into relative paths
  # ##start renaming, pixman first
  # install_name_tool -change $OUTDIR/lib/libpixman-1.0.dylib @loader_path/libpixman-1.0.dylib libpixman-1.0.dylib

  # #libfontconfig
  # install_name_tool -change $OUTDIR/lib/libfreetype.6.dylib @loader_path/libfreetype.6.dylib libfontconfig.dylib

  # ##cairo
  # install_name_tool -change $OUTDIR/lib/libcairo.2.dylib @loader_path/libcairo.2.dylib libcairo.dylib
  # install_name_tool -change $OUTDIR/lib/libpixman-1.0.dylib @loader_path/libpixman-1.0.dylib libcairo.dylib
  # install_name_tool -change $OUTDIR/lib/libfreetype.6.dylib @loader_path/libfreetype.6.dylib libcairo.dylib
  # install_name_tool -change $OUTDIR/lib/libpng15.15.dylib @loader_path/libpng15.15.dylib libcairo.dylib
  # install_name_tool -change $OUTDIR/lib/libfontconfig.1.dylib @loader_path/libfontconfig.1.dylib libcairo.dylib

  # install_name_tool -change $OUTDIR/lib/libcairo.2.dylib @loader_path/libcairo.2.dylib libcairo.2.dylib
  # install_name_tool -change $OUTDIR/lib/libpixman-1.0.dylib @loader_path/libpixman-1.0.dylib libcairo.2.dylib
  # install_name_tool -change $OUTDIR/lib/libfreetype.6.dylib @loader_path/libfreetype.6.dylib libcairo.2.dylib
  # install_name_tool -change $OUTDIR/lib/libpng15.15.dylib @loader_path/libpng15.15.dylib libcairo.2.dylib
  # install_name_tool -change $OUTDIR/lib/libfontconfig.1.dylib @loader_path/libfontconfig.1.dylib libcairo.2.dylib

  # #canvas.node
  # install_name_tool -change $OUTDIR/lib/libpixman-1.0.dylib @loader_path/libpixman-1.0.dylib canvas_osx.node
  # install_name_tool -change $OUTDIR/lib/libcairo.2.dylib @loader_path/libcairo.2.dylib canvas_osx.node
  # install_name_tool -change $OUTDIR/lib/libjpeg.8.dylib @loader_path/libjpeg.8.dylib canvas_osx.node
fi
cd .. ## exit binlib

#now at root of package

cp -rv ../test .
cd test
pwd
node -v
node test.js
# if this succeeds, we can archive and upload
cd ..


tar -cvzf ../$PACKAGEFILENAME ./*



cd ..


