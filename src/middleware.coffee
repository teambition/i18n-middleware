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

  middleware: ->
    options = @options

    _middleware = (req, res, next) =>
      i18n.init req, res, ->
        lang = i18n.getLocale(req)
        pathname = url.parse(req.url).pathname
        tmpPath = "#{options.tmp}/#{lang}"

        if matches = pathname.match(options.grepExts)

          _decorator = (ext) ->
            switch ext
              when '.js', '.coffee' then return (code) -> return "'#{code}'"
              else return (code) -> return code

          async.each options.testExts, ((_ext, _next) ->
            fileRelPath = pathname.replace(options.grepExts, _ext)
            filePath = path.join(options.src, fileRelPath)
            destPath = "#{options.tmp}/#{lang}#{fileRelPath}"

            _compile = ->
              fs.readFile filePath, 'utf8', (err, content) ->
                return _next() if err?  # file missing

                content = content.replace options.pattern or /$^/, (m, code) ->
                  result = i18n.__({phrase: code, locale: lang})
                  return if result then _decorator(_ext)(result) else code

                mkdirp path.dirname(destPath), '0755', (err) ->
                  return _next() if err?
                  fs.writeFile(destPath, content, 'utf8', _next)

            return _compile() if options.force

            fs.stat filePath, (err, srcStat) ->
              return _next() if err?
              fs.stat destPath, (err, destStat) ->
                if err
                  if err.code is 'ENOENT'
                    _compile()
                  else
                    return _next()
                else
                  if srcStat.mtime > destStat.mtime
                    _compile()
                  else
                    _next()
            ), (err) ->
            next()
        else
          next()

    return _middleware

i18nMiddleware = (options) ->
  @version = '0.0.1'
  middleware = new I18nMiddleware(options)
  @options = middleware.options
  return middleware.middleware()

module.exports = i18nMiddleware