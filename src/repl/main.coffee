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
      completions = '.connect .use .help .exit .quit'.split(' ')
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

questionPassword = (username) ->
  rl.question "Input Password: ", (password) ->
    connect username, password

promptSOQL = ->
  promptMode = "soql"
  rl.setPrompt "   #{_soqlBuffer.length}> "
  rl.prompt()

parseCommand = (line) ->
  argv = line.replace(/^\s*|\s*$/g, '').split(/\s+/)
  argv.unshift('soql', 'cmd') # dummy process arg
  cmd = new commander.Command;
  cmd.command('.connect <username> [password]')
     .description('Login to Salesforce using given username and password. Security token should be concatinated to the password if available.')
     .action (username, password) ->
        connect(username, password)
  cmd.command('.use [env]')
     .description('Change login server for user authentication. ' +
                  'Argument "env" must be "production", "sandbox", or hostname of login server.')
     .action (env) ->
        use(env)
        promptCommand()
  cmd.command('.help')
     .description('Show command help')
     .action ->
        showHelp(cmd.commands)
        promptCommand()
  cmd.command('.exit')
     .action -> exit()
  cmd.command('.quit')
     .action -> exit()
  cmd.parse(argv)

use = (env) ->
  switch env
    when 'production', 'prod'
      conn = new sf.Connection
        loginUrl: "https://login.salesforce.com"
    when 'sandbox'
      conn = new sf.Connection
        loginUrl: "https://test.salesforce.com"
    else
      conn = new sf.Connection
        loginUrl: "https://#{env}"
  console.log "Using #{env} for login server."

connect = (username, password) ->
  if username and password
    rl.pause()
    conn.login username, password, (err, res) ->
      rl.resume()
      if err
        console.error err.message
        questionPassword(username)
      else
        console.log "Logged in as: #{username}"
        promptCommand()
  else if username
    questionPassword(username)
  else
    promptCommand()

exit = ->
  console.log "Bye."
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

showHelp = (commands) ->
  console.log "\n  Commands:\n"
  for command in commands
    output = '   '
    output += command._name
    for arg in command._args
      [ lparen, rparen ] = if arg.required then "<>" else "[]"
      output += ' ' + lparen + arg.name + rparen
    output += '  '
    if command._description
      output += ' ' for i in [0...Math.max(0, 30 - output.length)]
      output += command._description
    console.log output
  console.log '\n'

###
###
init = ->
  program = new commander.Command()
  program.option('-u, --username [username]', 'Salesforce username')
         .option('-p, --password [password]', 'Salesforce password (and security token, if available.)')
         .option('-e, --env [env]', 'Login environment ("production","sandbox", or hostname of login server)')
         .parse(process.argv);
  if program.env
    use program.env
  if program.username
    connect program.username, program.password
  else
    promptCommand()

init()

