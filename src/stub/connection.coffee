###
# connection.coffee
###
metadata = require './data/metadata'

sobjects = {}
for sobject in metadata.sobjects
  sobjects[sobject.name.toUpperCase()] = sobject

exports.delay = 10 # delay for callback response in msec

exports.describeGlobal = (callback) ->
  setTimeout ->
    callback(null, metadata)
  , @delay

exports.describeSObject = (name, callback) ->
  setTimeout ->
    name = name.toUpperCase()
    if sobjects[name]?
      callback(null, sobjects[name])
    else
      callback({ message : 'Error' })
  , @delay
