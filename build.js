(function() {
    "use strict";

    var FILE_ENC = "utf-8";
    var SRC_DIR = ".\\src\\";
    var OUT_DIR = ".\\dist\\";
    var RES_DIR = ".\\res\\";

    var _fs = require("fs");
    var _run = require("child_process").exec;

    function build() {

        clean(OUT_DIR);

        var dest = OUT_DIR;
        console.log("creating directory " + dest)
        _fs.mkdirSync(dest);
        
        console.log("brewing coffee...")
        _run("coffee -cbm -o " + OUT_DIR + " -j app.js " + SRC_DIR);

        copyFiles(".\\src\\", ["main.html"], dest);

        dest = OUT_DIR + "lib\\";
        console.log("creating directory " + dest)
        _fs.mkdirSync(dest);
        copyFiles(".\\lib\\", _fs.readdirSync(".\\lib\\"), dest);

        dest = OUT_DIR + "res\\";
        console.log("creating directory " + dest)
        _fs.mkdirSync(dest);
        copyFiles(".\\res\\", _fs.readdirSync(".\\res\\"), dest);

        dest = OUT_DIR + "res\\shotgun\\";
        console.log("creating directory " + dest)
        _fs.mkdirSync(OUT_DIR + "res\\shotgun\\");
        copyFiles(".\\res\\shotgun\\", _fs.readdirSync(".\\res\\shotgun\\"), dest);
    }

    function copyFiles(fromDir, fileList, toDir) {
        for(var file = 0; file < fileList.length; ++file) {
            var fileName = fileList[file];
            var srcPath = fromDir + fileName;
            if (_fs.lstatSync(srcPath).isFile()) {
                console.log("copying " + fileName + " from " + fromDir + " to " + toDir);
                copy(srcPath, toDir + fileName);
            }
            else{
                console.log("not a file, cant copy: " + srcPath);
            }
        }
    }

    // copy a FILE, only files!
    function copy(from, to) {
        var fromStream = _fs.createReadStream(from);
        var toStream = _fs.createWriteStream(to);
        fromStream.pipe(toStream);
    }

    // deletes 'dir' and all subdirectories and files
    function clean(dir) {
        if (_fs.existsSync(dir)) {
            var objects = _fs.readdirSync(dir);
            delete_fs_objects(dir, objects);
            console.log("removing directory " + dir)
            _fs.rmdirSync(dir);
        }
    }

    function delete_fs_objects(dir, objects) {
        for(var i = 0; i < objects.length; ++i) {
            var object = dir + objects[i];
            if (_fs.lstatSync(object).isDirectory()) {
                clean(object + "\\");
            }
            else {
                console.log("deleting " + object);
                _fs.unlinkSync(object);
            }
        }
    }

    build();
})();
