path = require 'path'
fs = require 'fs'

# review, necessary?
selenium = require 'selenium-webdriver'
{Deferred} = selenium.promise
WebElement = selenium.WebElement

module.exports = (driver) ->
  #TMP
  sizzleCode = fs.readFileSync path.join __dirname, '../lib', 'sizzle.min.js'

  checkSizzleExists = ->
    console.log '- check sizzle'
    # driver.executeScript(-> window.$? or window.Sizzle?)
    driver.executeScript(-> window.Sizzle?)


  injectSizzle = ->
    console.log '- injectSizzle'

    sizzleCode = fs.readFileSync path.join __dirname, '../lib', 'sizzle.min.js'

    promise = driver.executeScript \
      """
        var module = {exports: {}};
        #{sizzleCode}
        window.Sizzle = module.exports;
      """
    promise


  # return a WebElement promise.
  getElement = (selector)->
    console.log '- getElement', selector

    elementPromise = driver.findElement selenium.By.js """
      try {
        var selector = #{JSON.stringify selector};
        console.log('hello', selector);
        console.log("[client] has sizzle?", !!window.Sizzle);
        console.log("[client] looking for '#{selector}'");
        var els = window.Sizzle(selector) || [];
        console.log("[client] els?", els);
        return els[0];
      } catch (err) {
        console.error("Failed", err, els);
      }
    """

    console.log 'getElement promise?', elementPromise

    # # REVIEW - copied from before
    # elementPromise.then null, (err) ->
    #   throw new Error "Selector #{selector} matches nothing"

    elementPromise


  one = (selector) ->
    console.log '- getting element zzz', selector

    d = new Deferred

    # first check if browser has jQuery/Zepto or Sizzle already available.
    checkSizzleExists()

    .then (sizzleExists)->
      console.log '-- sizzleExists?', sizzleExists

      unless sizzleExists
        console.log '- injecting sizzle'
        return injectSizzle()

    .then ->
      console.log '- finally getting el'

      elPromise = getElement(selector)
      d.fulfill elPromise

    # .then null, d.reject

    return new WebElement driver, d.promise



  all = (selector) ->
    driver.findElements selenium.By.js("""
      var module = {exports: {}};
      #{sizzleCode}
      var Sizzle = module.exports;
      return (Sizzle(#{JSON.stringify selector}) || []);
    """)

  one.all = all
  one
