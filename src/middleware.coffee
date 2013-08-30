path = require('path')
fs = require('fs')
url = require('url')
i18n = require('i18n')
_ = require('underscore')
async = require('async')
mkdirp = require('mkdirp')

class I18nMiddleware

  constructor: (options) ->
    @options = _.extend(
      locales: ['en']
      defaultLocale: 'en'
      cookie: 'lang'
      directory: "#{process.cwd()}/src/locales"
      src: "#{process.cwd()}/src"
      tmp: "#{process.cwd()}/.locales"
      grepExts: /(\.js|\.html)$/
      testExts: ['.coffee', '.html']
      pattern: /\{\{__([\s\S]+?)\}\}/g
      force: false
      options or {}
    )
    i18n.configure(@options)

  # ops: filePath, destPath, decorator, ext, lang
  compile: (ops, callback = ->) ->
    options = @options
    ops = ops

    _compile = ->
      fs.readFile ops.filePath, 'utf8', (err, content) ->
        return callback() if err?  # file missing
        content = content.replace options.pattern or /$^/, (m, code) ->
          result = i18n.__({phrase: code, locale: ops.lang})
          return if result then ops.decorator(ops.ext)(result) else code

        mkdirp path.dirname(ops.destPath), '0755', (err) ->
          return callback() if err?
          fs.writeFile(ops.destPath, content, 'utf8', callback)

    return _compile() if options.force

    fs.stat ops.filePath, (err, srcStat) ->
      return callback() if err?
      fs.stat ops.destPath, (err, destStat) ->
        if err
          if err.code is 'ENOENT'
            _compile()
          else
            return callback()
        else
          if srcStat.mtime > destStat.mtime
            _compile()
          else
            callback()

  middleware: ->
    options = @options

    _middleware = (req, res, next) =>
      i18n.init req, res, =>
        lang = i18n.getLocale(req)
        pathname = url.parse(req.url).pathname
        tmpPath = "#{options.tmp}/#{lang}"

        if matches = pathname.match(options.grepExts)

          _decorator = (ext) ->
            switch ext
              when '.js', '.coffee' then return (code) -> return "'#{code}'"
              else return (code) -> return code

          async.each options.testExts, ((_ext, _next) =>
            fileRelPath = pathname.replace(options.grepExts, _ext)
            filePath = path.join(options.src, fileRelPath)
            destPath = "#{options.tmp}/#{lang}#{fileRelPath}"

            _options = {
              filePath: filePath
              destPath: destPath
              decorator: _decorator
              ext: _ext
              lang: lang
            }

            @compile(_options, _next)

            ), (err) ->
            next()
        else
          next()

    return _middleware

i18nMiddleware = (options) ->
  middleware = new I18nMiddleware(options)
  @options = middleware.options
  return middleware.middleware()

i18nMiddleware.Class = I18nMiddleware

i18nMiddleware.version = '0.0.1'

module.exports = i18nMiddleware