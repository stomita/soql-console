###
# storage.coffee
###
module.exports =
  get: (key) ->
    localStorage.getItem(key)

  set: (key, value) ->
    localStorage.setItem(key, value)

  remove: (key) ->
    localStorage.removeItem(key)
