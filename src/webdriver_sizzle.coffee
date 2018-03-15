path = require 'path'
fs = require 'fs'

###
@param driver - a built driver instance
@param selenium - the selenium module.
very important that these are using the same code/version,
b/c of the library's global control flow.
###
module.exports = (driver, selenium = require('selenium-webdriver')) ->

  unless driver.executeScript? and driver.findElement? and driver.findElements?
    throw new Error "Driver passed to webdriver-sizzle must implement executeScript(), findElement() and findElements()."

  {Deferred} = selenium.promise
  {WebElement} = selenium

  checkSizzleExists = ->
    driver.executeScript(-> window.Sizzle?)

  injectSizzleIfMissing = (sizzleExists)->
    if sizzleExists then return
    else
      sizzleCode = fs.readFileSync path.join __dirname, '../lib', 'sizzle.min.js'
      driver.executeScript \
        """
          var module = {exports: {}};
          #{sizzleCode}
          window.Sizzle = module.exports;
        """

  one = (selector) ->
    finder = ->
      checkSizzleExists().then(injectSizzleIfMissing)
      .then ->
        driver.findElement selenium.By.js \
          (selector)->
            (window.Sizzle(selector)||[])[0]  # one
          , selector
      .catch (err)->
        throw new Error "Selector #{selector} matches nothing"

    driver.findElement(finder)

  one.all = (selector) ->
    finder = ->
      checkSizzleExists().then(injectSizzleIfMissing)
      .then ->
        driver.findElements selenium.By.js \
          (selector)->
            window.Sizzle(selector)||[]  # all
          , selector
      .catch (err)->
        throw new Error "Selector #{selector} matches nothing"

    driver.findElements(finder)

  one
