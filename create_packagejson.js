// file to create a package.json 
var fs = require('fs');

var original = require('./node-canvas/package'); // does automatic parsing

original.name = "canvas-binlibs";
delete original.scripts;
delete original.dependencies;
delete original.devDependencies;

var main;
if (process.platform === 'linux') {
  main = "binlib/canvas_linux_" + process.arch + ".node";
}
else if (process.platform === "win32") {
  main = "binlib/canvas.node";
}
else if (process.platform === "osx") {
  main = "binlib/canvas_osx.node";
}
original.main = main;

fs.writeFileSync('./node-canvas-bin-lib/package.json', JSON.stringify(original, null, 3));