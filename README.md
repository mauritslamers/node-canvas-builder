## Node-Canvas-Builder
A set of scripts to build binary packages for node-canvas. https://github.com/Automattic/node-canvas.

The manual scripts as described below have been merged into a single build script (build.sh) which is used for both linux and osx, which is targeted to be built on Travis. The windows build is done entirely in the appveyor script and only uses the test code from this repo to test whether the package works.

The binary packages which are created on release by Travis and AppVeyor are equal to the node-canvas-bin module from https://github.com/mauritslamers/node-canvas-bin but with platform specific binary libraries included.


### Old style manual builds: build_linux.sh and build_osx.sh
A set of scripts to build binary packages to be used with https://github.com/mauritslamers/node-canvas-bin.
In order to keep the download on install as small as possible, the node-canvas-bin package itself doesn't contain any binaries. On install, it will detect the platform and architecture, and install the right set of binaries as a subpackage of itself.

These subpackages are contained in the https://github.com/mauritslamers/node-canvas-bin-libs repository, where every platform has a separate orphaned branch containing the libraries themselves which reside in the binlib directory, as well as a package.json to enable the use of require() in the node-canvas-bin package.

The node-canvas-bin package only contains the JavaScript parts of the original node-canvas package.

The node-canvas-bin-libs package 

## Instructions for use

Make sure you have node installed and a global node-gyp.

### Mac OSX
 * Make sure you have the command line compiler installed through XCode
 * Make sure you have xz installed (through homebrew for example)
 * run build_osx.sh
 * if everything goes well, cd into node-canvas-bin-libs and commit

### Windows
There is no automated script yet so, the best is to do the following

 * Download GTK and extract it in C:\GTK
 * Checkout node-canvas as C:\node-canvas
 * Checkout node-canvas-bin-libs as C:\node-canvas-bin-libs and checkout the appropriate branch (win32 or win64)
 * cd into node-canvas and run npm install
 * if the process ends correctly, there will be a C:\node-canvas\build\Release\canvas.node
 * copy this file into the binlib directory of node-canvas-bin-libs
 * check whether the dlls which already exist in the binlib directory have the same version as the GTK dlls in C:\GTK
 * go to C:\, open the node console and try to require() the node-canvas-bin-libs package.
 * if you get errors, make sure that if you used a more recent version of GTK you also copy the 
   appropriate dll files into binlib folder

### Linux
The script will test for the presence of the required packages (the X.org header files among other things).
It is important to realize that there are two linux architectures, the 32bits i686 (which nodejs calls ia32) and the 64 bits x86_64.

WARNING: The script will __only__ build the binaries for the current platform, and will therefore not cross-compile!

After compilation the script will copy all required files into the node-canvas-bin-libs/binlib directory and will automatically write a new package.json and test the package. If it worked out ok, commit the changes and push the correct branch (and __only__ the correct branch!) to github.