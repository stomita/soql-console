###
# soql-autocompl.coffee
#
# Copyright 2012, Shinichi Tomita <shinichi.tomita@gmail.com>
#
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
          candidate = getSelectedCandidate()
          execCompletion(candidate) if candidate
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
    pivot = SoqlCompl.complete text, cpos, (err, res) ->
      setTimeout ->
        handleCandidates(text, cpos, res.candidates, res.pivot)
      , 10
    pt = textarea.charPosition(pivot)
    complMenu.empty()
      .append($('<li class="loading" style="font-style:italic">Loading...</li>'))
      .css(left: pt.left, top: pt.top + 28)
      .scrollTop(0)
      .show()

  ###
  ###
  handleCandidates = (text, cpos, candidates, pivot) ->
    if candidates.length == 0
      endCompletion()
    if completing
      input = text.substring(pivot, cpos).toUpperCase()
      matched = []
      for c in candidates 
        matched.push(c) if c.value?.toUpperCase().indexOf(input) == 0
      if matched.length == 1
        execCompletion(matched[0])
      else
        complMenu.empty()
        for c in candidates
          li = $('<li>')
            .data('value', c.value)
            .data('type', c.type)
            .data('fieldType', c.fieldType)
            .data('label', c.label)
            .append(
              do ->
                anchor = $('<a>')
                if c.fieldType
                  anchor.append(
                    $("<span class=\"label field-type field-type-#{c.fieldType}\">").text(c.fieldType))
                else
                  anchor.append(
                    $("<span class=\"label #{c.type}\">").text(c.type))
                anchor.append(' ')
                anchor.append($('<span>').text(c.value))
                if c.label
                  anchor.append($('<span class="display-label">').text(" (#{c.label})"))
                anchor
            ).appendTo(complMenu)
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
    selected = complMenu.find('li.active').first()
    {
      type: selected.data('type')
      fieldType: selected.data('fieldType')
      label: selected.data('label')
      value: selected.data('value')
    }

  ###
  ###
  selectFirstCandidate = ->
    complMenu.find('li').removeClass('active')
      .filter('.visible').first().addClass('active')

  ###
  ###
  moveToPrevCandidate = ->
    curr = complMenu.find('li.active')
    prev = curr.prevAll('li.visible').first()
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
    next = curr.nextAll('li.visible').first()
    if next.size() == 1
      curr.removeClass('active')
      next.addClass('active')
    else
      if complMenu.find('li.visible').size() == 1
        candidate = getSelectedCandidate()
        execCompletion(candidate)
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
  execCompletion = (candidate) ->
    text = textarea.val()
    word = candidate.value
    preText = text.substring(0, pivot)
    cpos = textarea.caretPosition()
    postText = text.substring(cpos)
    caret = pivot + word.length
    if candidate.type == "function"
      word += "()"
      caret += 1
    else if candidate.type == "field" && candidate.fieldType == "reference"
      word += "."
      caret += 1
    else if postText.length == 0
      word += " "
      caret += 1
    textarea.val(preText + word + postText)
    textarea.caretPosition(caret)
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
