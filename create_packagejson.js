// file to create a package.json
var fs = require('fs');

var original = require('./node-canvas/package'); // does automatic parsing

original.name = "canvas-binlibs";
delete original.scripts;
delete original.dependencies;
delete original.devDependencies;

var main;
if (process.platform === 'linux') {
  var arch = process.arch === "x64"? "x86_64" : "ia32";
  main = "binlib/canvas_linux_" + arch + ".node";
}
else if (process.platform === "win32") {
  main = "binlib/canvas.node";
}
else if (process.platform === "osx") {
  main = "binlib/canvas_osx.node";
}
original.main = main;

// also adjust node version
original.engines.node = ">= " + process.version.slice(1);

fs.writeFileSync('./node-canvas-bin-libs/package.json', JSON.stringify(original, null, 3));