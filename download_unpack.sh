#!/bin/bash
#
set -e

mkdir -p download

curl -L $URLPKGCONFIG -o download/pkgconfig.tgz
curl -L $URLPIXMAN -o download/pixman.tar.gz
curl -L $URLLIBFREETYPE -o download/libfreetype.tar.gz
curl -L $URLLIBFONTCONFIG -o download/libfontconfig.tar.gz
curl -L $URLLIBJPEG -o download/libjpeg.tar.gz
curl -L $URLLIBPNG -o download/libpng.tar.gz
curl -L $URLCAIRO -o download/cairo.tar.xz
curl -L $URLGIFLIB -o download/giflib.tar.gz

# now unpack into build

mkdir -p build
cd build

tar -xvzf ../download/pkgconfig.tgz
tar -xvzf ../download/pixman.tar.gz
tar -xvzf ../download/libfreetype.tar.gz
tar -xvzf ../download/libfontconfig.tar.gz
tar -xvzf ../download/libjpeg.tar.gz
tar -xvzf ../download/libpng.tar.gz
tar -xvzf ../download/giflib.tar.gz
tar -xvJf ../download/cairo.tar.xz

cd ..