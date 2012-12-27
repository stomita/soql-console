###
# node.coffee
###
class Node
  constructor: (config) ->
    @type = config.type if config.type?
    @value = config.value if config.value?
    if config.childNodes?
      @childNodes = config.childNodes 
      prev = null
      for cn, idx in @childNodes
        unless cn instanceof Node
          cfg = if typeof cn == 'object' then cn else { type: 'TERMINAL', value: cn }
          cn = new Node(cfg)
          @childNodes[idx] = cn
        cn.parent = @ 
        cn.prev = prev
        prev.next = cn if prev
        prev = cn
      if @childNodes.length == 1 && @childNodes[0].type == 'TERMINAL'
        @value = @childNodes[0].value
        delete @childNodes

  flatten: ->
    if @childNodes?
      arr = []
      for cn in @childNodes
        arr.push.apply(arr, cn.flatten()) 
      arr
    else
      [ @ ]

  path: ->
    path = @type
    path = @parent.path() + "/" + path if @parent 
    path

  print: (depth=0, println = console.log) ->
    lpad = new Array(depth+1).join(' ')
    if @childNodes?
      println "#{lpad}+ (#{@type})"
      for cn in @childNodes
        cn.print(depth+1)
    else
      println "#{lpad}- '#{@value}' (#{@type})"

  find: (type) ->
    if @childNodes?
      for cn in @childNodes
        return cn if match(type, cn.type)
      for cn in @childNodes
        n = cn.find(type)
        return n if n?
    null

  findPrevious: (type, stopType) ->
    n = @prev || @parent
    if not n? || match(stopType, n.type)
      null
    else if match(type, n.type)
      n
    else
      n.findPrevious(type, stopType)

  findParent: (type, stopType) ->
    if not @parent? || match(stopType, @parent.type)
      null 
    else if match(type, @parent.type)
      @parent 
    else
      @parent.findParent(type, stopType)


match = (type, target) ->
  if type instanceof RegExp 
    type.test(target)
  else
    type == target

module.exports = Node
