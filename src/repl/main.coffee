#
# main.coffee
#

sf = require 'node-salesforce'
readline = require 'readline'
stubConn = require '../stub/connection'
SoqlCompletion = require '../soql-completion'
SoqlCompletion.connection = stubConn

rl = readline.createInterface
  input: process.stdin
  output: process.stdout
  completer: (line, callback) ->
#    console.log rl
    if /^\s*\./.test line
      completions = '.connect .help .error .exit .quit'.split(' ')
      hits = completions.filter (c) -> return c.indexOf(line) == 0
      completions = if hits.length > 0 then hits else completions
      callback(null, [ completions, line ])
    else
      complSOQL = soql + rl.line
      cursor = soql.length + rl.cursor
# console.log complSOQL.substring(0, cursor) + "|" + complSOQL.substring(cursor)
      SoqlCompletion.complete complSOQL, cursor, (err, res) ->
        if err
          callback(null, [])
        else
          pivot = res.pivot - soql.length
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

soql = ""
username = ""

rl.setPrompt "SOQL> "
rl.prompt()
rl.on "line", (line) ->
  line = line.replace(/^\s+|\s+$/g, '')
  cmd = line.split(/\s+/)[0]
  switch cmd
    when '.connect'
      username = line.split(/\s+/)[1]
      password = line.split(/\s+/)[2]
      rl.pause()
      conn.login username, password, (err, res) ->
        if err
          console.error err.message
        else
          console.log "Logged In as " + username
          SoqlCompletion.connection = createConnCache(conn)
          SoqlCompletion.connection.describeGlobal (err, res) -> # for caching
          rl.setPrompt "SOQL> "
        rl.resume()
        rl.prompt()
    when '.exit', '.quit'
      rl.close()
    else
      soql = soql || ""
      soql += line.replace(/;$/, '') + "\n"
      if /;$/.test(line) || line == ""
        if conn.accessToken
          rl.pause()
          conn.query soql, (err, res) ->
            return console.error err.message if err
            console.log res
            rl.resume()
            rl.setPrompt "SOQL> "
            rl.prompt()
        else
          console.error "Not Logged In"
          rl.setPrompt "SOQL> "
          rl.prompt()
        soql = ""
      else
        rl.setPrompt "   *> "
        rl.prompt()
