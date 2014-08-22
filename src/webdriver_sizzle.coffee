path = require 'path'
fs = require 'fs'

###
@param driver - a built driver instance
@param selenium - the selenium module.
very important that these are using the same code/version,
b/c of the library's global control flow.
###
module.exports = (driver, selenium = require('selenium-webdriver')) ->

  unless driver instanceof selenium.WebDriver
    throw new Error "Driver passed to webdriver-sizzle must be a WebDriver instance."

  {Deferred} = selenium.promise
  {WebElement} = selenium

  checkSizzleExists = ->
    driver.executeScript(-> window.Sizzle?)

  injectSizzle = ->
    sizzleCode = fs.readFileSync path.join __dirname, '../lib', 'sizzle.min.js'
    driver.executeScript \
      """
        var module = {exports: {}};
        #{sizzleCode}
        window.Sizzle = module.exports;
      """


  # return a WebElement (promise).
  one = (selector) ->
    d = new Deferred

    checkSizzleExists()
    .then (sizzleExists)-> return injectSizzle() unless sizzleExists
    .then ->
      elementPromise = driver.findElement selenium.By.js \
      (selector)->
        (window.Sizzle(selector)||[])[0]
      , selector

      d.fulfill elementPromise

    .thenCatch (err) ->
      # gets caught and passed to next rejection handler
      throw new Error "Selector #{selector} matches nothing"

    return new WebElement driver, d.promise


  # return a promise that resolves to an array of WebElements.
  one.all = (selector) ->
    checkSizzleExists()
    .then (sizzleExists)-> injectSizzle() unless sizzleExists
    .then ->
      elementPromise = driver.findElements selenium.By.js \
      (selector)->
        (window.Sizzle(selector)||[])
      , selector

      # # REVIEW - is this the best way to control the error message?
      # elementPromise.then null, (err) ->
      #   throw new Error "Selector #{selector} matches nothing"

  one
