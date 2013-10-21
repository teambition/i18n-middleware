I18n = require('../lib/middleware').I18nMiddleware

i18n = new I18n({
  directory: "./locales"
  defaultLocale: 'en'
  locales: ['en', 'zh']
})

console.log i18n.__({phrase: 'testString', locale: 'en'}, 'test')

console.log i18n.__({phrase: 'testString', locale: 'zh'}, '测试')

console.log i18n.__({phrase: 'testArray', locale: 'en'}, ['test1', 'test2'])

console.log i18n.__({phrase: 'testArray', locale: 'zh'}, ['测试1', '测试2'])

console.log i18n.__({phrase: 'testArray', locale: 'en'}, ['test1'])