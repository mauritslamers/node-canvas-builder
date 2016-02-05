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
  # cp ../../node-canvas/build/Release/canvas_linux_$ARCH.node ./canvas_linux_$ARCH.node
  cp ../../node-canvas/build/Release/canvas.node ./canvas.node
  for f in libcairo.so.2 libpng15.so.15 libjpeg.so.8 libgif.so.4 libpixman-1.so.0 libfreetype.so.6
  do
    #don't take anything else, and we are interested in the file, not the symlink as it doesn't survive the install by npm
    cp $OUTDIR/lib/$f ./$f
  done
fi

if [[ $TRAVIS_OS_NAME == "osx" ]]; then

  # cp -v ../../node-canvas/build/Release/canvas_osx.node ./canvas_osx.node
  ls ../../node-canvas/build/Release
  cp -v ../../node-canvas/build/Release/canvas.node ./canvas.node
  chmod +w ./canvas.node #make sure it is writable

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

  # make readonly again
  chmod -w ./*
  ls -al

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


