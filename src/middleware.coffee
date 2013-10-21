path = require('path')
fs = require('graceful-fs')
url = require('url')
_ = require('underscore')
async = require('async')
mkdirp = require('mkdirp')

class I18nMiddleware

  @defaultOptions: {
    defaultLocale: 'en'
    cookie: 'lang'
    directory: "#{process.cwd()}/src/locales"
    src: "#{process.cwd()}/src"
    tmp: "#{process.cwd()}/tmp/i18n"
    grepExts: /(\.js|\.html)$/
    testExts: ['.coffee', '.html']
    pattern: /\{\{__([\s\S]+?)\}\}/g
    force: false
    updateFiles: false
  }

  constructor: (options) ->
    @options = _.extend(
      _.clone(I18nMiddleware.defaultOptions)
      options or {}
    )
    unless @options.locales
      try
        langFiles = fs.readdirSync(@options.directory).filter (fileName) ->
          if path.extname(fileName) is ".json" then true else false
        @options.locales = (f[..f.length-path.extname(f).length-1] for f in langFiles)
      catch
        @options.locales = []
    @init()

  init: ->
    @loadDict()

  _dict: (locale, dictPath) ->
    options = @options
    dictPath = path.join(process.cwd(), dictPath) if dictPath?
    try
      dict = require(path.resolve(path.join(dictPath or options.directory, locale)))
    catch e
      dict = {}
    for k, v of dict
      if k is '@include'
        for dictPath in v
          dict = _.extend(dict, @_dict(locale, dictPath))
    delete dict['@include']
    return dict

  loadDict: ->
    @dicts = {}
    options = @options
    {locales} = options
    locales = locales or [@options.defaultLocale]
    for locale in locales
      @dicts[locale] = @_dict(locale)
    return @dicts

  __: (param, value) ->
    {phrase, locale} = param

    _replace = (phraseVal)->
      return phraseVal unless phraseVal?
      switch typeof value
        when 'string'
          return phraseVal.replace('%s', value)
        when 'object'
          if value.length? and value.length > 0
            i = -1
            return phraseVal.replace /\%s/g, ->
              i +=1
              return value[i] || ''
      return phraseVal

    if @dicts[locale]?
      return _replace(@dicts[locale][phrase])
    return _replace(@dicts[@options.defaultLocale]?[phrase])

  # ops: filePath, destPath, lang
  compile: (ops, callback = ->) ->
    options = @options
    ops = ops

    _compile = =>
      fs.readFile ops.filePath, 'utf8', (err, content) =>
        return callback() if err?  # file missing
        content = content.replace options.pattern or /$^/, (m, code) =>
          result = @__({phrase: code, locale: ops.lang})
          return result or code

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

  guessLanguage: (req, res = null, next = ->) =>
    @_language = I18nMiddleware.guess(req, @options)

    req.locale = @_language or ''

    next()

  @guess: (handle, options) ->
    _options = _.extend(
      I18nMiddleware.defaultOptions
      options or {}
    )
    languageHeader = handle.headers['accept-language']
    language = null
    if _options.cookie? # Guess from cookie
      if handle.cookies?.lang?
        language = handle.cookies[_options.cookie] if handle.cookies[_options.cookie] in _options.locales
      else if handle.headers?.cookie?
        handle.headers.cookie.split(';').every (cookieString) =>
          [key, val] = cookieString.split('=')
          if key is _options.cookie
            language = val if val in  _options.locales
            return false
          return true

    if languageHeader? and not language?
      languageHeader.split(',').every (l) =>
        lang = l.split(';')[0]
        subLang = lang.split('-')[0]
        if lang in _options.locales
          language = lang
          return false
        if subLang in _options.locales
          language = subLang
          return false
        return true

    return language or _options.defaultLocale

  guess: (req) =>
    @guessLanguage(req)
    return @_language

  middleware: ->
    options = @options

    _middleware = (req, res, next) =>
      lang = @guess(req)
      pathname = url.parse(req.url).pathname
      tmpPath = "#{options.tmp}/#{lang}"

      if matches = pathname.match(options.grepExts)
        async.each options.testExts, ((_ext, _next) =>
          fileRelPath = pathname.replace(options.grepExts, _ext)
          filePath = path.join(options.src, fileRelPath)
          destPath = "#{options.tmp}/#{lang}#{fileRelPath}"
          _options = {
            filePath: filePath
            destPath: destPath
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
  return middleware.middleware()

i18nMiddleware.I18nMiddleware = I18nMiddleware

i18nMiddleware.guessLanguage = (options) ->
  middleware = new I18nMiddleware(options)
  return middleware.guessLanguage

i18nMiddleware.version = '0.0.1'

module.exports = i18nMiddleware