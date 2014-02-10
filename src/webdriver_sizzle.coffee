selenium = require 'selenium-webdriver'
path = require 'path'
fs = require 'fs'

module.exports = (driver) ->
  sizzleCode = fs.readFileSync path.join __dirname, '../lib', 'sizzle.min.js'

  (selector) ->
    driver.findElement selenium.By.js("""
      var module = {exports: {}};
      #{sizzleCode}
      var Sizzle = module.exports;
      return (Sizzle(#{JSON.stringify selector}) || [])[0];
    """)
