###
# result-table.coffee
###

render = (result) ->
  headers = {}
  rows = []
  for record in result.records
    for name, value in record
      scanHeaders(record, headers)
  for record in result.records
    row = recordToRow(record, headers)
    rows.push(row)
  {
    headers: headers
    rows: rows
  }

recordToRow = (record, headers) ->
  row = []
  for name, h of headers
    value = record[name]
    if isObject(value) && isObject(h)
      row = row.concat(recordToRow(value, h))
    else
      row.push(value)
  row

isObject = (v) ->
  typeof v == 'object' && v != null

scanHeaders = (record, headers) ->
  unless headers[name]
    if isObject(value)
      headers[name] = {}
      scanHeaders(value, headers[name])
    else
      headers[name] = typeof value



