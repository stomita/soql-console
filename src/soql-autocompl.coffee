###
# soql-autocompl.coffee
###
require "./caret"
SoqlCompl = require "./soql-completion"


###
###
autocomplete = (textarea, runQuery) ->
  ###
  ###
  textarea = $(textarea)

  ###
  ###
  completing = false
  pivot = -1

  complMenu =
    $('<ul class="autocompl-menu dropdown-menu">')
      .css
        position: 'absolute'
        margin: '0px'
        padding: '5px'
        'max-height': '150px'
        overflow: 'auto'
      .appendTo(document.body)

  ###
  ###
  textarea.keydown (e) ->
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
        e.preventDefault()
        e.stopPropagation()
        startCompletion()
      else if e.ctrlKey && e.keyCode == 13 # Ctrl + Return
        e.preventDefault()
        e.stopPropagation()
        runQuery?()

  textarea.keyup (e) ->
    if completing
      switch e.keyCode
        when 9, 13, 17, 27, 38, 40
          return
        when 32
          return if e.ctrlKey
        else
          #
      cpos = textarea.caretPosition()
      ch = textarea.val().charAt(cpos-1)
      if cpos < pivot || (cpos > pivot && /[\s+\.\,]/.test(ch))
        endCompletion()
      else
        input = $(@).val().substring(pivot, cpos)
        filterCandidates(input)

  textarea.click ->
    endCompletion() if completing

  textarea.blur ->
    endCompletion() if completing


  ###
  ###
  startCompletion = ->
    completing = true
    text = textarea.val()
    cpos = textarea.caretPosition()
    SoqlCompl.connection = module.exports.connection
    SoqlCompl.complete text, cpos, (candidates, index) ->
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
          p = textarea.charPosition(index)
          complMenu
            .empty()
            .css(left: p.left, top: p.top + 28)
            .scrollTop(0)
            .show()
          for candidate in candidates
            $('<li>')
               .data('value', candidate.value)
               .data('label', candidate.label)
               .append($('<a>').text(candidate.value))
               .appendTo(complMenu)
          filterCandidates(input)

  ###
  ###
  filterCandidates = (input) ->
    input = input.toUpperCase()
    complMenu.find('li').each ->
      el = $(@)
      value = el.data('value').toUpperCase()
      if value.indexOf(input) == 0
        el.addClass('visible').show()
      else
        el.removeClass('visible').hide()
    len = complMenu.find('li.visible').size()
    if len > 0
      complMenu.show()
    else
      complMenu.hide()
    selectFirstCandidate()

  ###
  ###
  getSelectedCandidate = ->
    complMenu.find('li.active').first().data('value')

  ###
  ###
  selectFirstCandidate = ->
    complMenu.find('li').removeClass('active')
      .filter('.visible').first().addClass('active')

  ###
  ###
  moveToPrevCandidate = ->
    curr = complMenu.find('li.active')
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
    complMenu.find('li').removeClass('active')
      .filter('.visible').last().addClass('active')

  ###
  ###
  moveToNextCandidate = ->
    curr = complMenu.find('li.active')
    next = curr.next('li.visible')
    if next.size() == 1
      curr.removeClass('active')
      next.addClass('active')
    else
      if complMenu.find('li.visible').size() == 1
        word = getSelectedCandidate()
        execCompletion(word)
      else
        selectFirstCandidate()
    adjustCandidateScroll()

  ###
  ###
  adjustCandidateScroll = ->
    top = complMenu.position().top
    height = complMenu.height()
    selected = complMenu.find('li.active')
    if selected.size() > 0
      first = complMenu.find('li.visible').first()
      ft = first.position().top
      st = selected.position().top
      sb = st + selected.height()
      if st < 0
        complMenu.scrollTop(st - ft)
      else if sb > height
        complMenu.scrollTop(sb - ft - height)

  ###
  ###
  execCompletion = (word) ->
    text = textarea.val()
    preText = text.substring(0, pivot)
    cpos = textarea.caretPosition()
    postText = text.substring(cpos)
    word += if postText.length == 0 then " " else ""
    textarea.val(preText + word + postText)
    textarea.caretPosition(pivot + word.length)
    endCompletion()

  ###
  ###
  endCompletion = ->
    completing = false
    pivot = -1
    complMenu.hide()


###
###
module.exports =
  connection: null
  autocomplete : autocomplete
