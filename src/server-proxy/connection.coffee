###
# connection.coffee
###
methodCache = require "method-cache"


responder = (callback) ->
  if typeof callback == 'function'
    onSuccess: (res) -> callback(null, res)
    onFailure: (err) -> callback(err)
  else
    callback

request = (message, callback) ->
  callback = responder(callback)
  $.ajax
    type: 'POST'
    url: '/proxy'
    contentType: 'application/json'
    dataType: 'json'
    data: JSON.stringify(message)
    success: (res) -> callback.onSuccess(res)
    error: (xhr) ->
      try
        error = JSON.parse(xhr.responseText)[0]
      catch e
        error = { message: xhr.responseText, errorCode: xhr.statusText }
      callback.onFailure(error)

###
###
module.exports = methodCache.create({

  initialize: (options) ->
    @accessToken = options.accessToken
    @instanceUrl = options.instanceUrl
    @id = options.id
    @version = options.version || '53.0'

  describeGlobal: (callback) ->
    request {
      method: 'GET'
      url: "#{@instanceUrl}/services/data/v#{@version}/sobjects"
      headers: {
        Authorization: "Bearer #{@accessToken}"
      }
    }, callback

  describeSObject: (name, callback) ->
    request {
      method: 'GET'
      url: "#{@instanceUrl}/services/data/v#{@version}/sobjects/#{name}/describe"
      headers: {
        Authorization: "Bearer #{@accessToken}"
      }
    }, callback

  getUserInfo: (callback) ->
    request {
      method: 'GET'
      url: "#{@id}"
      headers: {
        Authorization: "Bearer #{@accessToken}"
      }
    }, callback

  query: (soql, callback) ->
    request {
      method: 'GET'
      url: "#{@instanceUrl}/services/data/v#{@version}/query?q=#{encodeURIComponent(soql)}"
      headers: {
        Authorization: "Bearer #{@accessToken}"
      }
    }, callback
}
, 
{
  describeSObject: true
  describeGlobal: true
  getUserInfo: true
})