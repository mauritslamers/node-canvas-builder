#!/bin/bash
# nvm is not yet supported on osx, manually install
git clone https://github.com/creationix/nvm.git /tmp/.nvm
source /tmp/.nvm/nvm.sh
nvm install $NODE_VERSION
nvm use $NODE_VERSION