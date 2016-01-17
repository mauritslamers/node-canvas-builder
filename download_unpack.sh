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

tar -xzf ../download/pkgconfig.tgz
tar -xzf ../download/pixman.tar.gz
tar -xzf ../download/libfreetype.tar.gz
tar -xzf ../download/libfontconfig.tar.gz
tar -xzf ../download/libjpeg.tar.gz
tar -xzf ../download/libpng.tar.gz
tar -xzf ../download/giflib.tar.gz
tar -xJf ../download/cairo.tar.xz

cd ..