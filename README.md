# route-regex v1.1.0

Isomorphic route matching.

All route patterns must begin with `/`.

Any periods outside a regex pattern are escaped.

## Named parameters

When a named parameter is matched, its name is used
as the key in the `params` object.

The syntax is: `:name` or `:name(regex)`

When a named parameter has no regex pattern in
parentheses following it, the pattern defaults
to `[^./-]+`, which matches a string of one
or more characters that can't contain a period,
backslash, or dash.

To make a named parameter optional: `:name?` or `:name(regex)?`

```js
let re = routeRegex('/:name?')
assert(re.match('/test').name === 'test')
assert(re.match('/').name === undefined)
```

## Unnamed parameters

When an unnamed parameter is matched, its index is
used as the key in the `params` object.

The syntax is: `(regex)`

To make an unnamed parameter optional: `(regex)?`

```js
let re = routeRegex('/(\w+)')
assert(re.match('/abc')[1] === 'abc')
assert(re.match('/and1') === null)
```

## Nested parameters

Nested parameters are allowed, but you can't nest a
named parameter in any other parameter.

```js
let re = routeRegex('/(([a-z]+)(\d+))')
let params = re.match('/test123')
assert(params[1] === 'test123')
assert(params[2] === 'test')
assert(params[3] === '123')
```

## Ignored patterns

You can do `(?:regex)` if you want to use a regex
pattern for matching but you don't need its value
as a parameter.

You should never use `?:` with named parameters.

```js
let re = routeRegex('/(?:.*)')
assert(re.match('/test') === true)
assert(re.match('/') === true)
```

