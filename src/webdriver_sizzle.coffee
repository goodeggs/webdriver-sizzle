path = require 'path'
fs = require 'fs'

# review, necessary?
selenium = require 'selenium-webdriver'
{Deferred} = selenium.promise
WebElement = selenium.WebElement

module.exports = (driver) ->

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


  # return a WebElement promise.
  getElement = (selector)->
    elementPromise = driver.findElement selenium.By.js \
    (selector)->
      (window.Sizzle(selector) || [])[0]
    , selector

    # REVIEW - copied from before
    elementPromise.then null, (err) ->
      throw new Error "Selector #{selector} matches nothing"

    elementPromise


  one = (selector) ->
    d = new Deferred

    # first check if browser has jQuery/Zepto or Sizzle already available.
    checkSizzleExists()

    .then (sizzleExists)->
      unless sizzleExists
        return injectSizzle()

    .then ->
      elPromise = getElement(selector)
      d.fulfill elPromise

    # .then null, d.reject

    return new WebElement driver, d.promise


  # TODO
  all = (selector) ->
    sizzleCode = fs.readFileSync path.join __dirname, '../lib', 'sizzle.min.js'
    driver.findElements selenium.By.js("""
      var module = {exports: {}};
      #{sizzleCode}
      var Sizzle = module.exports;
      return (Sizzle(#{JSON.stringify selector}) || []);
    """)

  one.all = all
  one
