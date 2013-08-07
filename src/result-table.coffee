###
# result-table.coffee
###

convertToFlatTable = (result) ->
  headers = {}
  rows = []
  for record in result.records
    scanHeaders(record, headers)
  for record in result.records
    [].push.apply(rows, convertToFlatRows(record, headers))
  {
    headers: convertToFlatHeader(headers)
    rows: rows
  }

convertToFlatHeader = (headers) ->
  hdrs = []
  for hname, header of headers
    if isObject(header)
      cheaders = convertToFlatHeader(header)
      [].push.apply(hdrs, hname + "." + cheader for cheader in cheaders)
    else
      hdrs.push(hname)
  hdrs

convertToFlatRows = (record, headers) ->
  row = []
  childRows = []
  for name, h of headers
    value = record?[name]
    if isObject(h)
      if value?.records?.length > 0
        crows = []
        for v in value.records
          [].push.apply(crows, convertToFlatRows(v, h))
      else
        crows = convertToFlatRows(value, h)
      cfirst = crows.shift()
      for childRow in childRows
        childRow.push(null) for [0...cfirst.length]
      idx = row.length
      for crow in crows
        crow.unshift(null) for [0...idx]
        childRows.push(crow)
      row = row.concat(cfirst)
    else
      row.push(value)
      childRow.push(null) for childRow in childRows
  [ row ].concat(childRows)

isObject = (v) ->
  typeof v == 'object' && v != null

isArray = (v) ->
  Object.prototype.toString.call(v) == '[object Array]'

scanHeaders = (record, headers) ->
  for name, value of record
    continue if name == 'attributes'
    unless headers[name]
      if isObject(value)
        if value?.records?.length > 0
          cheaders = headers[name] = {}
          scanHeaders(v, cheaders) for v in value.records
        else 
          pheaders = headers[name] = {}
          scanHeaders(value, pheaders)
      else
        headers[name] = true

exports.convertToFlatTable = convertToFlatTable

