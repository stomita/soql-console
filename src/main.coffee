###
main.coffee
###

# dummy 
define "fs", {}
define "path", {}
define "file", {}
define "system", {}

require.config

require [ './soql-completion', './stub/connection', './caret' ], (compl, connection) ->
  $ ->
    compl.connection = connection
    compl.connection.delay = 1 # 1msec
    init(compl)

###
###
init = (compl) ->

  ###
  ###
  completing = false
  pivot = -1

  ###
  ###
  $('#queryBtn').click -> startQuery()

  $('#soql').keydown (e) ->
    if completing
      propagate = false
      switch e.keyCode
        when 9 # tab
          if e.shiftKey
            moveToPrevCandidate()
          else
            moveToNextCandidate()
        when 13 # return
          word = getSelectedCandidate()
          execCompletion(word) if word
        when 27 # ESC
          endCompletion()
        when 32 # Space
          if e.ctrlKey # Ctrl + Space
            if e.shiftKey
              moveToPrevCandidate()
            else
              moveToNextCandidate()
          else
            propagate = true
        when 38 # up
          moveToPrevCandidate()
        when 40 # down
          moveToNextCandidate()
        else
          propagate = true
      unless propagate
        e.preventDefault()
        e.stopPropagation()
    else
      if e.ctrlKey && e.keyCode == 32 || # Ctrl + Space
         e.keyCode == 9 # tab
        e.stopPropagation()
        e.preventDefault()
        startCompletion()
      else if e.ctrlKey && e.keyCode == 13 # Ctrl + Return
        startQuery()

  $('#soql').keyup (e) ->
    if completing
      switch e.keyCode
        when 9, 13, 27, 38, 40
          break
        else
          cpos = $('#soql').caretPosition()
          ch = $('#soql').val().charAt(cpos-1)
          if cpos < pivot || /[\s+\.\,]/.test(ch)
            endCompletion()
          else
            input = $(@).val().substring(pivot, cpos)
            filterCandidates(input)

  $('#soql').click ->
    endCompletion() if completing

  $('#soql').blur ->
    endCompletion() if completing

  $('#soql').focus()


  ###
  ###
  startCompletion = ->
    completing = true
    el = $('#soql')
    text = el.val()
    cpos = el.caretPosition()
    compl.complete text, cpos, (candidates, index) ->
      pivot = index
      input = text.substring(cpos, index).toUpperCase()
      if candidates.length == 0
        endCompletion()
      if completing
        matched = []
        for c in candidates 
          matched.push(c) if c.value?.toUpperCase().indexOf(input) == 0
        if matched.length == 1
          execCompletion(matched[0].value)
        else
          p = el.charPosition(index)
          $('#candidates')
            .empty()
            .css(left: p.left, top: p.top + 28)
            .scrollTop(0)
            .show()
          for candidate in candidates
            $('<li>')
               .data('value', candidate.value)
               .data('label', candidate.label)
               .append($('<a>').text(candidate.value))
               .appendTo($('#candidates'))
          filterCandidates(input)

  ###
  ###
  filterCandidates = (input) ->
    input = input.toUpperCase()
    $('#candidates li').each ->
      el = $(@)
      value = el.data('value').toUpperCase()
      if value.indexOf(input) == 0
        el.addClass('visible')
      else
        el.removeClass('visible')
    len = $('#candidates li.visible').size()
    console.log len
    if len > 0
      $('#candidates').show()
    else
      $('#candidates').hide()
    selectFirstCandidate()

  ###
  ###
  getSelectedCandidate = ->
    $('#candidates li.active').first().data('value')

  ###
  ###
  selectFirstCandidate = ->
    $('#candidates li').removeClass('active')
      .filter('.visible').first().addClass('active')

  ###
  ###
  moveToPrevCandidate = ->
    curr = $('#candidates li.active')
    prev = curr.prev('li.visible')
    if prev.size() == 1
      curr.removeClass('active')
      prev.addClass('active')
    else
      selectLastCandidate()
    adjustCandidateScroll()

  ###
  ###
  selectLastCandidate = ->
    $('#candidates li').removeClass('active')
      .filter('.visible').last().addClass('active')

  ###
  ###
  moveToNextCandidate = ->
    curr = $('#candidates li.active')
    next = curr.next('li.visible')
    if next.size() == 1
      curr.removeClass('active')
      next.addClass('active')
    else
      if $('#candidates li.visible').size() == 1
        word = getSelectedCandidate()
        execCompletion(word)
      else
        selectFirstCandidate()
    adjustCandidateScroll()

  ###
  ###
  adjustCandidateScroll = ->
    el = $('#candidates')
    top = el.position().top
    height = el.height()
    selected = $('#candidates li.active')
    if selected.size() > 0
      first = $('#candidates li.visible').first()
      ft = first.position().top
      st = selected.position().top
      sb = st + selected.height()
      if st < 0
        el.scrollTop(st - ft)
      else if sb > height
        el.scrollTop(sb - ft - height)

  ###
  ###
  execCompletion = (word) ->
    el = $('#soql')
    text = el.val()
    preText = text.substring(0, pivot)
    cpos = el.caretPosition()
    postText = text.substring(cpos)
    word += if postText.length == 0 then " " else ""
    el.val(preText + word + postText)
    el.caretPosition(pivot + word.length)
    endCompletion()

  ###
  ###
  endCompletion = ->
    completing = false
    pivot = -1
    $('#candidates').hide()


  ###
  ###
  startQuery = ->
    alert "not implemented yet"
    ###
    soql = $('#soql').val()
    compl.connection.query soql,
      onSuccess: (res) ->
      onFailure: (err) ->
    ###


