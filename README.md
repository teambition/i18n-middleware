i18n-middleware
------
I18N middleware for expressjs

# Usage:

## middleware

```coffeescript
i18nOptions =
  locales: ['en', 'zh-CN']  # chose your languages
  tmp: path.join(__dirname, 'tmp/i18n')  # temporary file path, if you don't need other middleware processing, you can use public

app.use(require('i18n-middleware')(i18nOptions))  # register middleware
```

## Options

* `locales` The language you want use
* `defaultLocale`: Default language, default is 'en'
* `directory` The path where you put your locale json files. (en.json, zh-CN.json, etc...)
* `cookie` The language cookie title, default is 'lang'
* `src` Source code path, default is 'src'
* `tmp` Temporary file path, default is 'tmp/i18n'
* `pattern` The pattern used for replacement, default is /\{\{__([\s\S]+?)\}\}/g (e.g. {{__Hello}})
* `force` Force recompile file, default is false

## i18n-cli

```
Usage: i18n-cli [action] options

Actions:
    compile      compile source files to the chosen language, or compile to any language with [all] option
    help         display the help message

Options:
    i18n-cli compile [lang]

Example:
    i18n-cli compile en     # compile source code to English
    i18n-cli compile all    # compile source code to all language defined in the locales directory
```

## LICENSE

MIT