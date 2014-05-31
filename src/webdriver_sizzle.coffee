selenium = require 'selenium-webdriver'
path = require 'path'
uglify = require 'uglify-js'
fs = require 'fs'

SIZZLE = 'window["___$_Sizzle__"]'

{Deferred} = selenium.promise
{WebElement} = selenium

getSizzleCode = ->
  fs.readFile require.resolve('sizzle'), 'utf8', (err, sizzleCode) ->
    return deferred.reject err if err?
    deferred.fulfill sizzleCode

  deferred = new Deferred

module.exports = (driver) ->
  hasSizzle = ->
    driver.executeScript("return typeof #{SIZZLE} !== 'undefined'").then (results) ->
      if results then deferred.fulfill() else deferred.reject()

    deferred = new Deferred

  injectSizzle = ->
    getSizzleCode().then (sizzleCode) ->
      driver.executeScript "var module = {exports: {}}; #{sizzleCode}; #{SIZZLE} = module.exports;"

  one = (selector) ->
    script = "return (#{SIZZLE}(#{JSON.stringify selector}) || [])[0];"
    lookup = ->
      driver.findElement(selenium.By.js script).then deferred.fulfill

    hasSizzle()
      .then lookup, -> injectSizzle().then lookup
      .then null, (err) -> throw new Error "Selector #{selector} matches nothing"

    new WebElement driver, deferred = new Deferred

  all = (selector) ->
    script = "return (#{SIZZLE}(#{JSON.stringify selector}) || []);"
    lookup = -> driver.findElements(selenium.By.js script)
    hasSizzle().then lookup, -> injectSizzle().then lookup

  one.all = all
  one
