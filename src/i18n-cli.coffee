i18n = require('i18n')
fs = require('graceful-fs')
path = require('path')
{exec} = require('child_process')
I18nMiddleware = require('./middleware').Class
async  = require('async')

class I18nCli

  constructor: (args) ->
    @action = args[0]
    @args = args[1..]

  run: ->
    unless @action and  @action in ['format', 'revert', 'compile', 'help']
      console.error('Error: params missing')
      @help()
      return false
    @[@action]()

  # switch to i18n regex format
  format: ->

  # revert to plain texts
  revert: ->

  # compile all source code to converted format
  compile: ->
    [lang] = @args
    lang = lang or 'all'
    directory = "#{process.cwd()}/src/locales"
    srcs = ['src/scripts', 'src/templates']
    destDir = "#{process.cwd()}/tmp/i18n"
    testExts = ['.coffee', '.html']

    options = {}
    options.force = true
    options.directory = directory

    i18nMiddleware = new I18nMiddleware(options)

    _compile = (lang, callback = ->) ->
      # Who can read these codes below? hiahiahia
      async.each srcs, ((src, next) ->

        async.each testExts, ((ext, _next) ->

          exec "find #{src} -name '*#{ext}'", (err, result) ->
            return _next(err) if err?

            async.each result.trim().split("\n"), ((file, __next) ->

              console.log "file: #{file}"

              i18nMiddleware.compile({
                filePath: file
                destPath: path.join(destDir, lang, path.relative('src', file))
                lang: lang
              }, __next)

              ), (err) ->
              _next(err)

          ), (err) ->
          next(err)

        ), (err) ->
        callback(err)

    # _compile(lang)
    if lang is 'all'
      fs.readdir directory, (err, langFiles) ->
        throw err if err?
        async.each langFiles, ((langFile, next) ->
          _compile(langFile[..langFile.length-path.extname(langFile).length-1], next)
          ), (err) ->
          throw err if err?
          console.log "i18n compile finish"
    else
      _compile lang, (err) ->
        throw err if err?
        console.log "i18n compile finish"

  help: ->
    console.log '''
      Usage: i18n-cli [action] options

      Actions:
        compile      compile source files to the chosen language, or compile to any language with [all] option
        help         display the help message

      Options:
        i18n-cli compile [lang]

      Example:
        i18n-cli compile en     # compile source code to English
        i18n-cli compile all    # compile source code to all language defined in the locales directory
    '''

i18nCli = ->
  i18nCli = new I18nCli(arguments[0])
  i18nCli.run()

module.exports = i18nCli