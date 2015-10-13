local evHub = require 'evHub'

evHub:on('h', function (...) 
    print('hello')
    print(...)
end)

evHub:once('hx', function (...) 
    print('helloxxxxxx')
    print(...)
end)

evHub:emit('h', { x = 3 }, 'yyoyoyo111')

evHub:emit('h', { x = 3 }, 'yyoyoyo2222')
evHub:emit('hx', { x = 1 }, 'yyoyoyo')
evHub:emit('hx', { x = 2 }, 'yyoyoyo')
evHub:emit('hx', { x = 3 }, 'yyoyoyo')