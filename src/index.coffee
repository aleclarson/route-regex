
paramRE = /:(\w+)(\()?|\(|\./g
parenRE = /\(|\)/g
skipRE = /\(\?(:|=)/

routeRegex = (path) ->

  if path instanceof RegExp
    path.match = path.exec
    return path

  if typeof path isnt 'string'
    throw Error 'Route path must be a string or RegExp object'

  if path[0] isnt '/'
    throw Error 'Route path must begin with /'

  ch = 0       # The last matched character index.
  params = []  # Parameter names

  source = ''
  while true
    m = paramRE.exec path

    # Pass through unmatched parts.
    index = if m then m.index else path.length
    if ch < index
      source += path.slice ch, index

    break if not m
    index += m[0].length
    switch m[0][0]

      when ':' # named parameter
        params.push m[1]
        if m[2]
          index = 1 + findClosingParen path, ch = index
          source += m = path.slice ch - 1, index
          matchCaptureGroups m.slice(1, -1), params
        else source += '([^./-]+)'

      when '(' # unnamed parameter
        index = 1 + findClosingParen path, ch = index
        source += m = path.slice ch - 1, index
        matchCaptureGroups m, params

      when '.' # dot literal
        source += '\\.'

    # Track the first unmatched character.
    paramRE.lastIndex = ch = index

  path = new RegExp '^' + source + '$'
  path.match = params.length and matchParams or path.test
  path.params = params.length and params or null
  path

matchParams = (path) ->
  if m = @exec path
  then getParams m, @params
  else null

getParams = (values, names) ->
  params = {}
  for i in [1...values.length]
    params[names[i - 1] or i - 1] = values[i]
  return params

matchCaptureGroups = (str, params) ->
  parenRE.lastIndex = 0
  skip = 0
  while m = parenRE.exec str
    if m[0] is '('
      ch = m.index
      if skip is 0 and !skipRE.test str.substr ch, 3
        params.push params.length + 1
      else skip += 1
    else skip -= 1 if skip isnt 0
  return

findClosingParen = (str, i) ->
  parenRE.lastIndex = i
  level = 0
  while true
    unless match = parenRE.exec str
      throw Error "Unmatched left paren in '#{str}'"
    if match[0] is ')'
      if level is 0
        return match.index
      else level -= 1
    else level += 1

module.exports = routeRegex
