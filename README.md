## Instructions for use

Make sure you have node installed and a global node-gyp.

### Mac OSX
 * Make sure you have the command line compiler installed through XCode
 * Make sure you have xz installed (through homebrew for example)
 * run build_osx.sh
 * if everything goes well, cd into node-canvas-bin and commit

### Windows
There is no automated script yet so, the best is to do the following
 * Download GTK and extract it in C:\GTK
 * Checkout node-canvas as C:\node-canvas
 * Checkout node-canvas-bin as C:\node-canvas-bin
 * cd into node-canvas, and run npm install
 * if the process ends correctly, there will be a C:\node-canvas\build\Release\canvas.node
 * copy this file into the same location, but in node-canvas-bin
 * go to the root of the node-canvas-bin package and run node index.js
 * if you get errors, make sure that if you used a more recent version of GTK you also copy the 
   appropriate dll files into the build/Release folder
