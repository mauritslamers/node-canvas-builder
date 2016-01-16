#!/bin/bash
# install extra stuff osx needs in order to build
echo running brew update
brew update > /dev/null
echo now installing deps through homebrew
brew install xz
brew install libpng
brew install freetype
brew install fontconfig
brew install giflib
brew install pixman
brew install libjpeg
brew install cairo