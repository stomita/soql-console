{spawn, exec} = require 'child_process'
fs     = require 'fs'
rjs    = require 'requirejs'
{sync:glob} = require 'glob'

task 'build', 'Rebuild the Jison parser', ->
  console.log "building parser..."
  parser = require('./src/grammar').parser
  fs.writeFileSync './build/compiled_parser.js', parser.generate()
  console.log "building js files..."
  coffee = spawn "coffee", [ "-o", "build", "-c" ].concat(glob("./src/*.coffee"))
  coffee.stdout.on 'data', (d) -> console.log d.toString('utf-8')
  coffee.stderr.on 'data', (d) -> console.log d.toString('utf-8')
  coffee.on 'exit', ->
    console.log "building amd src..."
    exec "r.js -convert build public/js"

task 'test', 'Test', ->
  console.log "test soql parser"
  require("./test/soql_test").run()


task 'clean', 'Cleanup', ->
  exec "rm -f build/*.js"
  exec "rm -rf public/js/*"
