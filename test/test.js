#!/usr/bin/env node

//automated test for node-canvas-bin
var isErrorFree = true;

var util = require('util');

var os = require('os');
var canvas = require('../binlib/canvas');
// switch (os.platform()) {
//   case 'darwin': canvas = require('../binlib/canvas_osx'); break;
//   case 'win32': canvas = require('../binlib/canvas'); break;
//   case 'linux':
//     var arch = os.arch();
//     if (arch === "ia32") canvas = require('../binlib/canvas_linux');
//     if (arch === "x64") canvas = require('../binlib/canvas_linux_x64');
//     break;
//   default:
//     console.log("Unsupported platform");
//     process.exit(1);
// }


var file = require('fs').readFileSync('italic.png');
var img = new canvas.Image();
img.onerror = function(){
  util.log('Error while loading image: ' + util.inspect(arguments));
  util.log('If the above error was an "out of memory" error, cairo most likely has a problem with libpng warnings');
  isErrorFree=false;
};

img.source = file;
if(!img.complete){
  util.log('WARNING: image still loading? usually this is not good');
  isErrorFree = false;
}
if(img.height === 0 && img.width === 0){
  util.log('WARNING: image width and height are zero');
  isErrorFree = false;
}

if (isErrorFree) util.log("if you didn't see warnings, then the binary package is shipping worthy");
else process.exit(1);
