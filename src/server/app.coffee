###
Module dependencies.
###
express = require "express"
http = require "http"
path = require "path"
url = require "url"
request = require "request"

app = express()
app.configure ->
  app.set "port", process.env.PORT or 3000
  app.use express.favicon()
  app.use express.logger("dev")
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static(path.join(__dirname, "../public"))

app.configure "development", ->
  app.use express.errorHandler()


app.post "/proxy", (req, res) ->
  message = req.body
  if message.url
    urlParsed = url.parse(message.url)
    if urlParsed.protocol == 'https:' &&
       urlParsed.hostname.match(/\.(salesforce|force|database)\.com$/)
      # console.log message
      request(message).pipe(res)
    else
      res.send(400, "invalid url")
  else
    res.send(400, "invalid url")


http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")

