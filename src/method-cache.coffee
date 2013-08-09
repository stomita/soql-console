###
# method-cache.coffee
###
exports.create = (obj, cacheables) ->

  proxy = {}
  resultCaches = {}
  methodQueues = {}

  createCachableMethod = (obj, method) ->
    ->
      args = Array.prototype.slice.apply(arguments)
      callback = args.pop()
      key = createCacheKey(method, args)
      appendMethodQueue(key, callback)
      if resultCaches[key]
        flushQueue(key)
      else
        methodCallback = createMethodCallback(key)
        obj[method].apply(obj, args.concat(methodCallback))

  createCacheKey = (method, args) ->
    method + '_' + args.join('_')

  appendMethodQueue = (key, callback) ->
    if typeof callback == 'function'
      cb = 
        onSuccess : (res) -> callback(null, res)
        onFailure : (err) -> callback(err)
    else
      cb = callback
    queue = methodQueues[key] || []
    queue.push(cb)
    methodQueues[key] = queue
 
  createMethodCallback = (key) ->
    {
      onSuccess: (result) ->
        resultCaches[key] = { type : 'Success', result : result }
        flushQueue(key)
      onFailure: (error) ->
        resultCaches[key] = { type : 'Failure', result : error }
        flushQueue(key)
    }

  flushQueue = (key) ->
    result = resultCaches[key]
    queue = methodQueues[key] || []
    while queue.length>0
      callback = queue.pop()
      try
        callback['on'+result.type](result.result);
      catch e


  proxy = {}

  for prop, value of obj
    if typeof value == 'function'
      if cacheables[prop]
        proxy[prop] = createCachableMethod(obj, prop)
      else
        proxy[prop] = do (prop) ->
          -> obj[prop].apply(obj, arguments)


  proxy._cache = resultCaches
  proxy._createCacheKey = createCacheKey
  proxy.clearCache = ->
    delete resultCaches[key] for key of resultCaches
  proxy
