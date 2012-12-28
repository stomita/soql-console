###
# connection.coffee
###
metadata = require './data/metadata'

sobjects = {}
for sobject in metadata.sobjects
  sobjects[sobject.name.toUpperCase()] = sobject

exports.describeGlobal = (callback) ->
  callback(null, metadata)

exports.describeSObject = (name, callback) ->
  name = name.toUpperCase()
  if sobjects[name]?
    callback(null, sobjects[name])
  else
    callback({ message : 'Error' })
