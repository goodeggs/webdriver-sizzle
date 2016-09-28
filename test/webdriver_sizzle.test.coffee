assert = require 'assert'
path = require 'path'
webdriver = require 'selenium-webdriver'
webdriverSizzle = require '..'

{WebElement} = webdriver
{Deferred} = webdriver.promise

url = (page) ->
  "file://#{path.join __dirname, page}"

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
        $('.test-el').then (el) ->
          assert (el instanceof WebElement), 'is a WebElement'
          el.getText().then (text) ->
            assert.equal text, "The following text is an excerpt from Finnegan's Wake by James Joyce"
            done()

      it 'can also be chained', (done) ->
        $('.test-el').getText().then (text) ->
          assert.equal text, "The following text is an excerpt from Finnegan's Wake by James Joyce"
          done()

      describe 'that matches no elements', ->
        it 'rejects with an error that includes the selector', (done) ->
          $('.does-not-match')
          .catch (expectedErr) ->
            assert /does-not-match/.test(expectedErr?.message)
            done()

        it 'rejection is also passed down chain', (done) ->
          $('.does-not-match').getText()
          .catch (expectedErr) ->
            assert /does-not-match/.test(expectedErr?.message)
            done()

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
