{exec} = require "child_process"

#option '-d', '--debug', 'do not strip debug output'

task 'build', 'builds the project', (options) ->
    exec "coffee --compile --bare --map --output .\\dist\\ --join app.js .\\src\\", (err, stdout, stderr) ->
        throw err if err
        console.log stdout + stderr
    exec "copy .\\src\\main.html .\\dist\\main.html /y"
    exec "xcopy .\\res .\\dist\\res /e /i /y"
