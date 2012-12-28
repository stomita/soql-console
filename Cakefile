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
  coffee.stdout.pipe(process.stdout, end: false)
  coffee.stderr.pipe(process.stderr, end: false)
  coffee.on 'exit', ->
    console.log "building amd src..."
    exec "r.js -convert build public/js"

task 'test', 'Test', ->
  dataDir = './test/stub/data/'
  files = fs.readdirSync dataDir
  for file in files when file.match(/\.json$/)
    console.log file
    data = fs.readFileSync dataDir + file, 'utf-8'
    fname = file.replace(/\.json$/, '')
    fs.writeFileSync "#{dataDir}/#{fname}.js", "module.exports=#{data}", "utf-8"
  mocha = spawn "mocha", [ "--compilers", "coffee:coffee-script", "-R", "spec", "--colors" ]
  mocha.stdout.pipe(process.stdout, end: false)
  mocha.stderr.pipe(process.stderr, end: false)
  mocha.on 'exit', -> process.exit()

task 'clean', 'Cleanup', ->
  exec "rm -f build/*.js"
  exec "rm -rf public/js/*"
