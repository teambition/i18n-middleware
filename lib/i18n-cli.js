// Generated by CoffeeScript 1.6.3
(function() {
  var I18nCli, I18nMiddleware, async, exec, fs, i18n, i18nCli, path;

  i18n = require('i18n');

  fs = require('graceful-fs');

  path = require('path');

  exec = require('child_process').exec;

  I18nMiddleware = require('./middleware').Class;

  async = require('async');

  I18nCli = (function() {
    function I18nCli(args) {
      this.action = args[0];
      this.args = args.slice(1);
    }

    I18nCli.prototype.run = function() {
      var _ref;
      if (!(this.action && ((_ref = this.action) === 'format' || _ref === 'revert' || _ref === 'compile' || _ref === 'help'))) {
        console.error('Error: params missing');
        this.help();
        return false;
      }
      return this[this.action]();
    };

    I18nCli.prototype.format = function() {};

    I18nCli.prototype.revert = function() {};

    I18nCli.prototype.compile = function() {
      var destDir, directory, i18nMiddleware, lang, options, srcs, testExts, _compile;
      lang = this.args[0];
      lang = lang || 'all';
      directory = "" + (process.cwd()) + "/src/locales";
      srcs = ['src/scripts', 'src/templates'];
      destDir = "" + (process.cwd()) + "/tmp/i18n";
      testExts = ['.coffee', '.html'];
      options = {};
      options.force = true;
      options.directory = directory;
      i18nMiddleware = new I18nMiddleware(options);
      _compile = function(lang, callback) {
        if (callback == null) {
          callback = function() {};
        }
        return async.each(srcs, (function(src, next) {
          return async.each(testExts, (function(ext, _next) {
            return exec("find " + src + " -name '*" + ext + "'", function(err, result) {
              if (err != null) {
                return _next(err);
              }
              return async.each(result.trim().split("\n"), (function(file, __next) {
                console.log("file: " + file);
                return i18nMiddleware.compile({
                  filePath: file,
                  destPath: path.join(destDir, lang, path.relative('src', file)),
                  lang: lang
                }, __next);
              }), function(err) {
                return _next(err);
              });
            });
          }), function(err) {
            return next(err);
          });
        }), function(err) {
          return callback(err);
        });
      };
      if (lang === 'all') {
        return fs.readdir(directory, function(err, langFiles) {
          if (err != null) {
            throw err;
          }
          return async.each(langFiles, (function(langFile, next) {
            return _compile(langFile.slice(0, +(langFile.length - path.extname(langFile).length - 1) + 1 || 9e9), next);
          }), function(err) {
            if (err != null) {
              throw err;
            }
            return console.log("i18n compile finish");
          });
        });
      } else {
        return _compile(lang, function(err) {
          if (err != null) {
            throw err;
          }
          return console.log("i18n compile finish");
        });
      }
    };

    I18nCli.prototype.help = function() {
      return console.log('Usage: i18n-cli [action] options\n\nActions:\n  compile      compile source files to the chosen language, or compile to any language with [all] option\n  help         display the help message\n\nOptions:\n  i18n-cli compile [lang]\n\nExample:\n  i18n-cli compile en     # compile source code to English\n  i18n-cli compile all    # compile source code to all language defined in the locales directory');
    };

    return I18nCli;

  })();

  i18nCli = function() {
    i18nCli = new I18nCli(arguments[0]);
    return i18nCli.run();
  };

  module.exports = i18nCli;

}).call(this);