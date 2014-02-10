selenium = require 'selenium-webdriver'
path = require 'path'
fs = require 'fs'

module.exports = (driver) ->
  sizzleCode = fs.readFileSync path.join __dirname, '../lib', 'sizzle.min.js'

  one = (selector) ->
    driver.findElement selenium.By.js("""
      var module = {exports: {}};
      #{sizzleCode}
      var Sizzle = module.exports;
      return (Sizzle(#{JSON.stringify selector}) || [])[0];
    """)

  all = (selector) ->
    driver.findElements selenium.By.js("""
      var module = {exports: {}};
      #{sizzleCode}
      var Sizzle = module.exports;
      return (Sizzle(#{JSON.stringify selector}) || []);
    """)

  one.all = all
  one


