#
# main.coffee
#

commander = require 'commander'
sf = require 'node-salesforce'
readline = require './readline'
stubConn = require '../stub/connection'
SoqlCompletion = require '../soql-completion'
SoqlCompletion.connection = stubConn



completeCommand = (line, callback) ->
#    console.log rl
    if /^\s*\./.test line
      completions = '.connect .help .error .exit .quit'.split(' ')
      hits = completions.filter (c) -> return c.indexOf(line) == 0
      completions = if hits.length > 0 then hits else completions
      callback(null, [ completions, line ])
    else
      bufferSOQL = _soqlBuffer.join('\n') + '\n'
      complSOQL = bufferSOQL + rl.line
      cursor = bufferSOQL.length + rl.cursor
      SoqlCompletion.complete complSOQL, cursor, (err, res) ->
        if err
          callback(null, [])
        else
          pivot = res.pivot - bufferSOQL.length
          inputStr = line.substring(pivot).toUpperCase()
          candidates = res.candidates.filter (c) -> c.value.toUpperCase().indexOf(inputStr) == 0
          callback(null, [ candidates.map((c) -> c.value) , line.substring(pivot) ])


conn = new sf.Connection()

createConnCache = (conn) ->
  _sobjects: {}
  _globals: null

  describeSObject : (sobject, callback) ->
    type = sobject.toUpperCase()
    if @_sobjects[type]?
      callback(null, @_sobjects[type])
    else
      conn.sobject(sobject).describe (err, res) =>
        return callback(err) if err
        @_sobjects[type] = res
        callback(null, res)

  describeGlobal: (callback) ->
    if @_globals?
      callback(null, @_globals)
    else
      conn.describeGlobal (err, res) =>
        @_globals = res
        callback(null, res)

###
###

promptMode = "command"

rl = readline.createInterface
  input: process.stdin
  output: process.stdout
  completer: completeCommand

rl.on "line", (line) ->
  if promptMode == "command" && /^\s*\./.test(line)
    parseCommand line
  else
    processSOQL line

rl.on "SIGINT", (e) ->
  if promptMode == "command" && rl.line == ""
    rl.close() 
  else
    rl.clearLine()
    promptCommand()


_soqlBuffer = []

promptCommand = ->
  _soqlBuffer = []
  promptMode = "command"
  rl.setPrompt "SOQL> "
  rl.prompt()

promptSOQL = ->
  promptMode = "soql"
  rl.setPrompt "   *> "
  rl.prompt()

parseCommand = (line) ->
  argv = line.replace(/^\s*|\s*$/g, '').split(/\s+/)
  argv.unshift('soql', 'cmd') # dummy process arg
  cmd = new commander.Command;
  cmd.command('.connect [username] [password]')
     .action (username, password) ->
        connect username, password
  cmd.command('.exit')
     .action ->
       exit()
  cmd.command('.quit')
     .action ->
       exit()
  cmd.command('*')
     .action ->
        promptCommand()
  cmd.parse(argv)

connect = (username, password) ->
  if username and password
    rl.pause()
    conn.login username, password, (err, res) ->
      rl.resume()
      if err
        console.error err.message
      else
        console.log "Logged in as: " + username
      promptCommand()
  else
    promptCommand()

exit = ->
  console.log "Bye!"
  rl.close()

processSOQL = (line) ->
  _soqlBuffer.push(line.replace(/;\s*$/, ''))
  if /;\s*$/.test(line) || line == ""
    executeQuery _soqlBuffer.join('\n')
  else
    promptSOQL()

executeQuery = (soql) ->
  if conn.accessToken
    rl.pause()
    conn.query soql, (err, res) ->
      if err
        console.error err.message
      else
        showQueryResult(res)
      rl.resume()
      promptCommand()
  else
    console.error "Not Logged In"
    promptCommand()

showQueryResult = (res) ->
  console.log res


###
###
init = ->
  program = new commander.Command()
  program.option('-u, --username [username]', 'Salesforce username')
         .option('-p, --password [password]', 'Salesforce password', '')
         .option('-e, --environment [env]', 'Login server environment (production/sandbox)', 'production')
         .parse(process.argv);
  if program.username
    connect program.username, program.password
  else
    promptCommand()

init()

