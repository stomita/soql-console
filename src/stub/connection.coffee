###
# connection.coffee
###
metadata = require './data/metadata'

sobjects = {}
for sobject in metadata.sobjects
  sobjects[sobject.name.toUpperCase()] = sobject

exports.delay = 10 # delay for callback response in msec

responder = (callback) ->
  if typeof callback == 'function'
    {
      onSuccess: (res) -> callback(null, res)
      onFailure: (err) -> callback(err)
    }
  else
    callback

module.exports =

  initialize: (options) ->

  describeGlobal: (callback) ->
    setTimeout ->
      responder(callback).onSuccess(metadata)
    , @delay

  describeSObject: (name, callback) ->
    setTimeout ->
      name = name.toUpperCase()
      if sobjects[name]?
        responder(callback).onSuccess(sobjects[name])
        callback(null, sobjects[name])
      else
        responder(callback).onFailure( message: 'Error' )
    , @delay

  getUserInfo: (callback) ->
    responder(callback).onFailure(message: 'not logged in')

  query: (soql, callback) ->
    responder(callback).onFailure(message: 'You must login first to query database.')
