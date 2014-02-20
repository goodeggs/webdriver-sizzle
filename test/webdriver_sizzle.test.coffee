assert = require 'assert'
path = require 'path'
webdriver = require 'selenium-webdriver'
webdriverSizzle = require '..'

url = (page) ->
  "file://#{path.join __dirname, page}"

assertUncaught = (regex, done) ->
  listeners = process.listeners 'uncaughtException'
  process.removeAllListeners 'uncaughtException'
  process.once 'uncaughtException', (err) ->
    assert regex.test err.message, "#{err.message} doesn't match #{regex}"
    listeners.forEach (listener) -> process.on 'uncaughtException', listener
    done()

describe 'webdriver-sizzle', ->
  $ = null

  describe 'once driving a webdriver Builder', ->
    before (done) ->
      driver = new webdriver.Builder()
        .withCapabilities(webdriver.Capabilities.phantomjs())
        .build()
      @timeout 0 # this may take a while in CI
      driver.get(url 'finnegan.html').then -> done()

      $ = webdriverSizzle(driver)

    describe 'calling with a CSS selector', ->
      it 'returns the first matching webdriver element', (done) ->
        $('.test-el').getText().then (text) ->
          assert.equal text, "The following text is an excerpt from Finnegan's Wake by James Joyce"
          done()

      describe 'that matches no elements', ->
        it 'throws an error that includes the selector', (done) ->
          $('.does-not-match').getText()
          assertUncaught /does-not-match/, done

    describe 'all', ->
      it 'returns all matching elements', (done) ->
        $.all('p').then (elements) ->
          assert.equal elements.length, 2
          done()


