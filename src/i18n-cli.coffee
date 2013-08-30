i18n = require('i18n')
fs = require('fs')
{exec} = require('child_process')
I18nMiddleware = require('./middleware').Class
async  = require('async')

class I18nCli

  constructor: (args) ->
    @action = args[0]
    @args = args[1..]

  run: ->
    unless @action and  @action in ['format', 'revert', 'compile', 'help']
      console.error('params missing')
      return false
    @[@action]()

  # switch to i18n regex format
  format: ->

  # revert to plain texts
  revert: ->

  # compile all source code to converted format
  compile: ->
    [lang, directory, src, testExts] = @args
    options = {}
    options.force = true
    lang = lang or 'all'
    directory = directory or "#{process.cwd()}/src/locales"
    src = src or 'src'
    testExts = testExts?.split(',') or ['.coffee', '.html']

    i18nMiddleware = new I18nMiddleware(options)

    fileList = []
    async.eachSeries testExts, ((ext, next) ->
      exec "find #{src} -name '*#{ext}'", (err, result) ->
        return next(err) if err?
        fileList = fileList.concat(result.trim().split("\n"))
        next()
      ), (err) ->
      throw err if err?

      async.each fileList, ((file, next) ->
        # TODO: compile file to desc dirs
        ), (err) ->

    # i18nMiddleware.compile()

  help: ->

i18nCli = ->
  i18nCli = new I18nCli(arguments[0])
  i18nCli.run()

module.exports = i18nCli