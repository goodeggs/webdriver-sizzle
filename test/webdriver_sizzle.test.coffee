assert = require 'assert'
path = require 'path'
webdriver = require 'selenium-webdriver'

webdriverSizzle = require '..'

{WebElement} = webdriver
{Deferred} = webdriver.promise

url = (page) ->
  "file://#{path.join __dirname, page}"

# hack to work around then not working below,
# hijack mocha's uncaughtException handler.
assertUncaught = (regex, done) ->
  listeners = process.listeners 'uncaughtException'
  process.removeAllListeners 'uncaughtException'
  process.once 'uncaughtException', (err) ->
    listeners.forEach (listener) -> process.on 'uncaughtException', listener
    assert regex.test err.message, "#{err.message} doesn't match #{regex}"
    done()


describe 'webdriver-sizzle', ->
  $ = null
  driver = null

  before ->
    chromeCapabilities = webdriver.Capabilities.chrome()
    chromeCapabilities.set('chromeOptions', {args: ['--headless']})

    driver = new webdriver.Builder()
      .forBrowser('chrome')
      .withCapabilities(chromeCapabilities)
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
          .then(
            () ->
              done(new Error('expected promise to reject'))
            (expectedErr) ->
              assert /does-not-match/.test(expectedErr?.message)
              done()
          )

        # TODO? -- this doesn't work, b/c of the way it's implemented
        # in selenium-webdriver. doesn't seem that critical to work around.
        it.skip 'rejection is also passed down chain', (done) ->
          $('.does-not-match').getText()
          .then (expectedErr) ->
            assert /does-not-match/.test(expectedErr?.message)
            done()

        # (alternative to above)
        it 'chained methods causes error to be thrown', (done) ->
          $('.does-not-match').getText()
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
