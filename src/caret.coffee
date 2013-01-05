###
# caret.coffee
###

###
###
getPosition = (el) ->
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
setPosition = (el, pos) ->
  el.selectionStart = el.selectionEnd = pos 


###
###
shadow = null

###
###
getCharPosition = (el, index) ->
  text = el.val()
  unless shadow
    shadow = $('<div>').appendTo($(document.body))
    shadow.css(
      position: 'absolute'
      opacity: 0
      top: -1000
      left: -1000
      resize: 'none'
    )
  shadow.empty()
  shadow.css(
    width: el.width()
    "padding-top": el.css("padding-top")
    "padding-bottom": el.css("padding-bottom")
    "font-size": el.css('font-size')
    "font-weight": el.css('font-weight')
    "font-family": el.css('font-family')
    "font-color": "red"
    "line-height": el.css('line-height')
  )
  preText = $('<span>').html(htmlesc(text.substring(0, index))).appendTo(shadow)
  postText = $('<span>').html(htmlesc(text.substring(index) || '_')).appendTo(shadow)
  charPos = postText.position()
  basePos = el.position()
  {
    left: basePos.left + charPos.left
    top: basePos.top + charPos.top
  }

###
###
htmlesc = (str) ->
  (str || '').replace(/</g, '&lt;').replace(/>/g, '&gt;')
             .replace(/&/g, '&amp;').replace(/"/g, '&quot;')
             .replace(/\n/g, '<br>')


###
###
if jQuery?
  jQuery.fn.caretPosition = (pos) ->
    el = $(@).filter('textarea').first().get(0)
    if pos?
      setPosition(el, pos)
      @
    else
      getPosition(el)

  jQuery.fn.charPosition = (index) ->
    el = $(@).filter('textarea').first()
    if el then getCharPosition(el, index) else null


module.exports =
  getPosition: getPosition
  setPosition: setPosition


