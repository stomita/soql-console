fs = require 'fs'
path = require 'path'

module.exports = (grunt) ->
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-simple-mocha'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-requirejs'

  grunt.initConfig

    watch:
      files: "src/**/*.coffee"
      tasks: [ "build" ]

    coffee:
      compile:
        expand: true
        cwd: 'src/'
        src: [ '**/*.coffee' ]
        dest: 'src/'
        ext: '.js'
      test:
        expand: true
        cwd: 'test/'
        src: [ '**/*.coffee' ]
        dest: 'test/'
        ext: '.js'
    amd:
      build:
        cwd: 'src/'
        src: [ '**/*.js' ]
        dest: 'public/js/'

    simplemocha:
      options:
        reporter: 'spec'
        slow: 200
        timeout: 1000
      all:
        src: "test/**/*.js"

    clean:
      src: [
        "src/**/*.js"
        "!src/compiled_parser.js"
        "test/**/*.js"
        "public/js/**/*.js"
      ]


  grunt.registerMultiTask 'amd', 'Wrap .js files for amd.', ->
    @files.forEach (file) ->
      file.src.map (filepath) ->
        original = grunt.file.read(path.join(file.cwd, filepath))
        grunt.file.write(file.dest + filepath, 'define(function(require, exports, module) {\n' + original + '\n});\n\n')

  grunt.registerTask 'build:parser', ->
    console.log "building parser..."
    done = @async()
    parser = require('./src/grammar').parser
    fs.writeFile './src/compiled_parser.js', parser.generate(), 'utf-8', done

  grunt.registerTask 'build:stub', ->
    console.log "building stub data..."
    dataDir = './src/stub/data/'
    stat = null
    files = fs.readdirSync dataDir
    for file in files when file.match(/\.json$/)
      console.log file
      data = fs.readFileSync dataDir + file, 'utf-8'
      fname = file.replace(/\.json$/, '')
      fs.writeFileSync "#{dataDir + fname}.js", "module.exports=#{data}", "utf-8"

  grunt.registerTask 'build', [ 'build:parser', 'build:stub', 'coffee:compile', 'amd', 'coffee:test', 'simplemocha' ]
  grunt.registerTask 'default', 'build'

