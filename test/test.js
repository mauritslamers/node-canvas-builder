#!/usr/bin/env node

//automated test for node-canvas-bin
var isErrorFree = true;

var util = require('util');
var canvas = require('../node-canvas-bin-libs');
var file = require('fs').readFileSync('italic.png');
var img = new canvas.Image();
img.onerror = function(){
  util.log('Error while loading image: ' + util.inspect(arguments));
  util.log('If the above error was an "out of memory" error, cairo most likely has a problem with libpng warnings');
  isErrorFree=false;
};
img.src = file;
if(!img.complete){
  util.log('WARNING: image still loading? usually this is not good');
  isErrorFree = false;
}
if(img.height === 0 && img.width === 0){
  util.log('WARNING: image width and height are zero');
  isErrorFree = false;
}
if(isErrorFree) util.log("if you didn't see warnings, then the binary package is shipping worthy");
