###
main.coffee
###

# dummy 
define "fs", {}
define "path", {}
define "file", {}
define "system", {}

require [ './lexer', './parser' ], (lexer, parser) ->

  ###
  ###
  $('#soql').keydown (e) ->
    if e.ctrlKey && e.keyCode == 32 # Ctrl + Space
      e.stopPropagation();
      e.preventDefault();
      startCompletion()
    else if completing && e.keyCode == 27 # ESC
      endCompletion()

  completing = false

  ###
  ###
  startCompletion = ->
    completing = true
    el = $('#soql')
    text = el.val()
    caret = getCaret(el.get(0))
    tokens = lexer.tokenize(text)
    { pos, inserting } = findCaretPosition(tokens, caret)
    if inserting
      pos++
      tokens.splice(pos, 0, [ "LITERAL" , "", 1, caret ])
    debugTokens tokens
    startParse tokens, pos

  ###
  ###
  processCompletion = (tokens, target, results) ->
    input = tokens[target][1].toUpperCase()
    candidates = []
    for r in results
      if typeof r == 'string'
        candidates.push(r)
      else if r.type == 'ObjectType'
        candidates.push('Account', 'Contact', 'Opportunity', 'Contract')
      else if r.type == 'FieldName'
        candidates.push('Id', 'Name', 'CreatedDate', 'Parent')
    candidates = (word for word in candidates when word.toUpperCase().indexOf(input.toUpperCase()) == 0)
    console.log(input, candidates)
    if candidates.length == 1
      $('#candidates').empty()
      execCompletion(tokens, target, candidates[0])
    else
      $('#candidates').empty().show()
      for word in candidates
        $('#candidates').append($('<li>').data('word', word).text(word))

  execCompletion = (tokens, target, word) ->
    el = $('#soql')
    text = el.val()
    caret = getCaret(el.get(0))
    preText = if target >=1 then text.substring(0, tokens[target][3]) else ""
    postText = text.substring(preText.length + tokens[target][1].length)
    word += if postText.length == 0 then " " else ""
    el.val(preText + word + postText)
    el.focus();
    setCaret(el.get(0), caret + word.length)

  ###
  ###
  endCompletion = ->
    completing = false
    $('#candidates').hide()

  ###
  ###
  findCaretPosition = (tokens, caret) ->
    for i in [0...tokens.length - 1]
      tpos = tokens[i][3]
      tlen = tokens[i][1].length
      ntpos = tokens[i+1][3]
#      console.log("tpos=#{tpos},tlen=#{tlen},ntpos=#{ntpos},caret=#{caret}")
      if ntpos >= caret
        ret = { pos: i, inserting: caret > tpos + tlen }
        return ret
    { pos: tokens.length, inserting: true }

  ###
  ###
  startParse = (_tokens, _target) ->

    tryParse = (tokens, target, depth=0) ->
      return [] if depth > 10
      debugTokens(tokens)
      try
        tree = parser.parse(tokens)
        tree.print()
        stokens = tree.flatten()
        console.log(stokens)
        return [ stokens[target] ]
      catch e
        epos = e.pos - 1
        console.log e.message, "err pos=#{epos}, target=#{target}"
        return [] unless e.expected?
        expected = (name.substring(1, name.length-1) for name in e.expected)
        console.log "expected", expected
        if epos == target
          candidates = []
          for name in expected
            words = lexer.dictionary[name]
            candidates.push.apply(candidates, words) if words
          console.log candidates
          return candidates
        else
          etoken = getExpectedToken(expected, tokens[epos])
          tokens = Array.prototype.slice.call(tokens)
          tokens.splice(epos, 0, etoken)
          inc = if epos < target then 1 else 0
          return tryParse(tokens, target+inc, depth+1)

    candidates = tryParse(_tokens, _target)
    processCompletion(_tokens, _target, candidates)

  ###
  ###
  getExpectedToken = (names, actual) ->
    p = lexer.priority
    names = names.sort (n1, n2) ->
      p1 = p[n1] ? 100
      p2 = p[n2] ? 100
      if p1 > p2 then 1 else if p1 < p2 then -1 else 0
    for name in names
      words = lexer.dictionary[name] || lexer.examples[name]
      if words && words.length > 0
        return [ name, words[0], actual[2], actual[3] ]
    null

  ###
  ###
  debugTokens = (tokens) ->
    console.log (token[1]+"("+token[0]+":"+token[3]+")" for token in tokens).join(' ')


  ###
  ###
  getCaret = (el) ->
    if el.selectionStart
      return el.selectionStart; 
    else if document.selection
      el.focus()
      r = document.selection.createRange()
      return 0 if r == null

      re = el.createTextRange()
      rc = re.duplicate()
      re.moveToBookmark(r.getBookmark())
      rc.setEndPoint('EndToStart', re) 
      return rc.text.length 
    0

  ###
  ###
  setCaret = (el, pos) ->
    el.selectionStart = el.selectionEnd = pos 


