###
main.coffee
###

# dummy 
define "fs", {}
define "path", {}
define "file", {}
define "system", {}

require.config

require [ './soql-completion', './stub/connection' ], (SoqlCompletion, connection) ->

  SoqlCompletion.connection = connection
  SoqlCompletion.connection.delay = 1 # 1msec

  ###
  ###
  completing = false
  pivot = -1

  ###
  ###
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

  $('#soql').keyup (e) ->
    if completing
      switch e.keyCode
        when 9, 13, 27, 38, 40
          break
        else
          caret = getCaret()
          if caret < pivot
            endCompletion()
          else
            input = $(@).val().substring(pivot, caret)
            filterCandidates(input)

  $('#soql').click ->
    endCompletion() if completing

  $('#soql').blur ->
    endCompletion() if completing

  ###
  ###
  startCompletion = ->
    completing = true
    el = $('#soql')
    text = el.val()
    caret = getCaret()
    SoqlCompletion.complete text, caret, (candidates, index) ->
      pivot = index
      input = text.substring(caret, index).toUpperCase()
      if candidates.length == 0
        endCompletion()
      if completing
        matched = []
        for c in candidates 
          matched.push(c) if c.value?.toUpperCase().indexOf(input) == 0
        if matched.length == 1
          execCompletion(matched[0].value)
        else
          $('#candidates').empty().show()
          for candidate in candidates
            $('<li>')
               .data('value', candidate.value)
               .data('label', candidate.label)
               .text(candidate.value)
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
    selectFirstCandidate()

  ###
  ###
  getSelectedCandidate = ->
    $('#candidates li.selected').first().data('value')

  ###
  ###
  selectFirstCandidate = ->
    $('#candidates li').removeClass('selected')
      .filter('.visible').first().addClass('selected')

  ###
  ###
  moveToPrevCandidate = ->
    curr = $('#candidates li.selected')
    prev = curr.prev('li.visible')
    if prev.size() == 1
      curr.removeClass('selected')
      prev.addClass('selected')
    else
      selectLastCandidate()

  ###
  ###
  selectLastCandidate = ->
    $('#candidates li').removeClass('selected')
      .filter('.visible').last().addClass('selected')

  ###
  ###
  moveToNextCandidate = ->
    curr = $('#candidates li.selected')
    next = curr.next('li.visible')
    if next.size() == 1
      curr.removeClass('selected')
      next.addClass('selected')
    else
      if $('#candidates li.visible').size() == 1
        word = getSelectedCandidate()
        execCompletion(word)
      else
        selectFirstCandidate()

  ###
  ###
  execCompletion = (word) ->
    el = $('#soql')
    text = el.val()
    preText = text.substring(0, pivot)
    caret = getCaret()
    postText = text.substring(caret)
    word += if postText.length == 0 then " " else ""
    el.val(preText + word + postText)
    setCaret(pivot + word.length)
    endCompletion()

  ###
  ###
  endCompletion = ->
    completing = false
    pivot = -1
    $('#candidates').hide()

  ###
  ###
  getCaret = ->
    el = $('#soql').get(0)
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
  setCaret = (pos) ->
    el = $('#soql').get(0)
    el.selectionStart = el.selectionEnd = pos 


