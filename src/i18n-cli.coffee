i18n = require('i18n')
fs = require('graceful-fs')
path = require('path')
{exec} = require('child_process')
{I18nMiddleware} = require('./middleware')
async  = require('async')
logger = require('graceful-logger')
_ = require('underscore')

errorQuit = ->
  logger.err.apply(logger, arguments)
  process.exit()

quote = (text) ->
  return text.replace(/[-\\^$*+?.()|[\]{}]/g, "\\$&")

findAllFiles = (filePaths, patterns, callback) ->
  findCmds = []
  for filePath in filePaths
    for pattern in patterns
      findCmds.push("find #{filePath} -name '#{pattern}'")
  findResults = []
  async.each findCmds, ((findCmd, next) ->
    exec findCmd, (err, result) ->
      return next(err) if err?
      findResults = findResults.concat(result.trim().split("\n")) if result.length > 0
      next()
    ), (err) ->
    callback(err, findResults)

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
  format: (revert = false) ->
    [lang] = @args
    return errorQuit('missing language option') unless lang?
    i18nMiddleware = new I18nMiddleware()
    _i18n = i18nMiddleware.i18n
    dict = _i18n.getCatalog(lang)
    return errorQuit("missing language locales file [#{lang}.json]") unless dict
    srcs = ['src/scripts', 'src/templates']
    textExts = ['*.coffee', '*.html']

    findAllFiles srcs, textExts, (err, files) ->
      return errorQuit(err) if err?
      async.each files, ((file, next) ->
        fs.readFile file, 'utf8', (err, text) ->
          for tag, raw of dict
            if revert  # revert the raw, tag order
              text = text.replace(new RegExp(quote("{{__#{tag}}}")), raw)
            else
              text = text.replace(new RegExp(raw, 'g'), "{{__#{tag}}}")
          fs.writeFile(file, text, next)
        ), (err) ->
        logger.info("#{if revert then 'revert' else 'format'} finish")

  # revert to plain texts
  revert: ->
    @format(true)

  # compile all source code to converted format
  compile: ->
    [lang] = @args
    lang = lang or 'all'
    directory = "#{process.cwd()}/src/locales"
    srcs = ['src/scripts', 'src/templates']
    destDir = "#{process.cwd()}/tmp/i18n"
    textExts = ['*.coffee', '*.html']

    options = {}
    options.force = true
    options.directory = directory

    i18nMiddleware = new I18nMiddleware(options)

    _compile = (lang, callback = ->) ->
      findAllFiles srcs, textExts, (err, files) ->
        return errorQuit if err?
        async.each files, ((file, next) ->
          logger.info(file)
          i18nMiddleware.compile({
            filePath: file
            destPath: path.join(destDir, lang, path.relative('src', file))
            lang: lang
            }, next)
          ), (err) ->
          callback(err)

    if lang is 'all'
      fs.readdir directory, (err, langFiles) ->
        errorQuit(err) if err?
        async.each langFiles, ((langFile, next) ->
          _compile(langFile[..langFile.length-path.extname(langFile).length-1], next)
          ), (err) ->
          errorQuit(err) if err?
          logger.info("i18n compile finish")
    else
      _compile lang, (err) ->
        errorQuit(err) if err?
        logger.info("i18n compile finish")

  help: ->
    console.log '''
      Usage: i18n-cli [action] options

      Actions:
        compile      compile source files to the chosen language, or compile to any language with [all] option
        format       auto format raw text to tags
        revert       revert tags to plain text
        help         display the help message

      Options:
        i18n-cli compile [lang]

      Example:
        i18n-cli compile en     # compile source code to English
        i18n-cli compile all    # compile source code to all language defined in the locales directory
        i18n-cli format zh-CN   # compile source code which written in Chinese to i18n tags
        i18n-cli revert zh-CN   # revert i18n tags in source code to plain Chinese
    '''

i18nCli = ->
  i18nCli = new I18nCli(arguments[0])
  i18nCli.run()

module.exports = i18nCli