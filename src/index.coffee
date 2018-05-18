
paramRE = /:(\w+)|\(|\./g
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

  if path is '/'
    path = /^\/(?=[#?]|$)/
    path.match = path.test
    path.params = null
    return path

  ch = 0       # The last matched character index.
  params = []  # Parameter names

  # This comes in handy after the loop.
  endsWithLookahead = false

  # Build up the regex pattern!
  source = '^'
  while true
    m = paramRE.exec path

    # Pass through unmatched parts.
    index = if m then m.index else path.length
    if ch < index
      source += path.slice ch, index

    break if not m
    switch m[0][0]

      when ':' # named parameter
        index += m[0].length
        params.push m[1]

        # Use the default pattern unless a non-skip capture group exists.
        if path[index] isnt '(' or skipRE.test path.substr index, 3
          source += '([^./-]+)'
        else
          ch = index
          index = 1 + findClosingParen path, ch + 1
          source += m = path.slice ch, index
          matchCaptureGroups m.slice(1, -1), params

      when '(' # unnamed parameter
        ch = index + 1
        index = 1 + findClosingParen path, ch
        source += m = path.slice ch - 1, index
        matchCaptureGroups m, params

        # Check if the path ends with a lookahead.
        if index is path.length and path.substr(ch, 2) is '?='
          endsWithLookahead = true

      when '.' # dot literal
        source += '\\.'
        index++

    # Track the first unmatched character.
    paramRE.lastIndex = ch = index

  if !(endsWithLookahead or source.endsWith '$')
    source += '(?=[/#?]|$)'

  path = new RegExp source
  path.match = params.length and matchParams or path.test
  path.params = params.length and params or null
  path

matchParams = (path) ->
  if m = @exec path
  then getParams m, @params
  else null

getParams = (values, names) ->
  params = 0: values[0]
  for i in [1...values.length]
    params[names[i - 1] or i] = values[i]
  return params

# This function assumes parens are balanced.
matchCaptureGroups = (str, params) ->
  parenRE.lastIndex = 0
  skip = 0
  while m = parenRE.exec str
    if m[0] is '('
      ch = m.index
      prefix = str.substr ch, 3
      continue if prefix is '(?:'
      if !skip and prefix isnt '(?='
        params.push params.length + 1
      else skip += 1
    else skip -= 1 if skip isnt 0
  return

findClosingParen = (str, i) ->
  parenRE.lastIndex = i
  level = 0
  while true
    unless match = parenRE.exec str
      throw Error "Unmatched left paren in '#{str}' at index #{i}"
    if match[0] is ')'
      if level is 0
        return match.index
      else level -= 1
    else level += 1

module.exports = routeRegex
