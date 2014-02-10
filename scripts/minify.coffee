fs = require 'fs'
uglify = require 'uglify-js'

console.log uglify.minify(
  require.resolve('sizzle')
  output:
    ascii_only: true
).code
