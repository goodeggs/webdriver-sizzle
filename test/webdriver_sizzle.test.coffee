assert = require 'assert'
path = require 'path'
webdriver = require 'selenium-webdriver'
webdriverSizzle = require '..'

{Deferred} = webdriver.promise

url = (page) ->
  "file://#{path.join __dirname, page}"

# hack to work around thenCatch not working below,
# hijack mocha's uncaughtException handler.
assertUncaught = (regex, done) ->
  listeners = process.listeners 'uncaughtException'
  process.removeAllListeners 'uncaughtException'
  process.once 'uncaughtException', (err) ->
    assert regex.test err.message, "#{err.message} doesn't match #{regex}"
    listeners.forEach (listener) -> process.on 'uncaughtException', listener
    done()


describe 'webdriver-sizzle', ->
  $ = null
  driver = null

  before ->
    driver = new webdriver.Builder()
      .withCapabilities(webdriver.Capabilities.phantomjs())
      .build()
    @timeout 0 # this may take a while in CI

  describe 'once driving a webdriver Builder', ->
    before (done) ->
      $ = webdriverSizzle(driver)
      driver.get(url 'finnegan.html').then -> done()

    describe 'calling with a CSS selector', ->
      it 'returns the first matching webdriver element', (done) ->
        $('.test-el').getText().then (text) ->
          assert.equal text, "The following text is an excerpt from Finnegan's Wake by James Joyce"
          done()

      describe 'that matches no elements', ->
        it 'throws an error that includes the selector', (done) ->
          p = $('.does-not-match').getText()

          ## not sure why this doesn't work. rejection doesn't seem to trickle down.
          # p.then -> done new Error "Did not get expected error"
          # p.thenCatch (expectedErr) ->
          #   console.log {expectedErr}
          #   assert /does-not-match/.test(expectedErr?.message)
          #   done()

          # workaround
          assertUncaught /does-not-match/, done

    describe 'all', ->
      it 'returns all matching elements', (done) ->
        $.all('p').then (elements) ->
          assert.equal elements.length, 2
          done()
        , (err) ->
          done err

      it 'returns empty array when no matching elements', (done) ->
        $.all('section').then (elements) ->
          assert.equal elements.length, 0
          done()
        , (err) ->
          done err
